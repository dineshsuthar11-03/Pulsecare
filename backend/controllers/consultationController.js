const { createClient } = require('@supabase/supabase-js');
const { sendTextEmail } = require('../services/emailService');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);

const DEFAULT_SLOT_MINUTES = 60;
const ACTIVE_BOOKING_STATUSES = ['scheduled', 'ongoing'];
const SCHEDULING_UTC_OFFSET_MINUTES = Number(
  process.env.SCHEDULING_UTC_OFFSET_MINUTES || 330,
);
const DAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const pad2 = (value) => String(value).padStart(2, '0');

const isValidDateString = (value) => /^\d{4}-\d{2}-\d{2}$/.test(value || '');

const parseDateString = (dateString) => {
  const [year, month, day] = dateString.split('-').map(Number);
  return { year, month, day };
};

const parseTimeToMinutes = (timeText) => {
  if (!timeText || typeof timeText !== 'string' || !timeText.includes(':')) {
    return null;
  }

  const [hourText, minuteText] = timeText.split(':');
  const hour = Number(hourText);
  const minute = Number(minuteText);

  if (
    Number.isNaN(hour) ||
    Number.isNaN(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  return hour * 60 + minute;
};

const formatMinutesAsTime = (minutes) => {
  const hour = Math.floor(minutes / 60);
  const minute = minutes % 60;
  return `${pad2(hour)}:${pad2(minute)}`;
};

const coerceSlotMinutes = (value) => {
  const parsed = Number(value);
  if (Number.isNaN(parsed) || parsed < 15 || parsed > 180) {
    return DEFAULT_SLOT_MINUTES;
  }
  return parsed;
};

const toShiftedLocalDate = (date) =>
  new Date(date.getTime() + SCHEDULING_UTC_OFFSET_MINUTES * 60000);

const getLocalDateKey = (date) => {
  const shifted = toShiftedLocalDate(date);
  const year = shifted.getUTCFullYear();
  const month = shifted.getUTCMonth() + 1;
  const day = shifted.getUTCDate();
  return `${year}-${pad2(month)}-${pad2(day)}`;
};

const getLocalWeekday = (date) => {
  const shifted = toShiftedLocalDate(date);
  return DAY_NAMES[shifted.getUTCDay()];
};

const getLocalMinutesOfDay = (date) => {
  const shifted = toShiftedLocalDate(date);
  return shifted.getUTCHours() * 60 + shifted.getUTCMinutes();
};

const localDateTimeToUtcDate = ({ year, month, day, hour, minute }) => {
  const utcMs =
    Date.UTC(year, month - 1, day, hour, minute, 0, 0) -
    SCHEDULING_UTC_OFFSET_MINUTES * 60000;
  return new Date(utcMs);
};

const getUtcDayRangeForLocalDate = (dateString) => {
  const { year, month, day } = parseDateString(dateString);
  const start = localDateTimeToUtcDate({ year, month, day, hour: 0, minute: 0 });
  const nextDayStart = localDateTimeToUtcDate({
    year,
    month,
    day: day + 1,
    hour: 0,
    minute: 0,
  });

  return {
    startIso: start.toISOString(),
    nextDayStartIso: nextDayStart.toISOString(),
  };
};

const normalizeAvailability = (rawAvailability) => {
  const availability = rawAvailability && typeof rawAvailability === 'object'
    ? rawAvailability
    : {};
  const days = availability.days && typeof availability.days === 'object'
    ? availability.days
    : {};

  const startMinutes = parseTimeToMinutes(
    availability.start_time || availability.startTime || '09:00',
  );
  const endMinutes = parseTimeToMinutes(
    availability.end_time || availability.endTime || '17:00',
  );

  return {
    days,
    startMinutes: startMinutes == null ? 9 * 60 : startMinutes,
    endMinutes: endMinutes == null ? 17 * 60 : endMinutes,
    slotMinutes: coerceSlotMinutes(
      availability.slot_minutes || availability.slotMinutes || DEFAULT_SLOT_MINUTES,
    ),
  };
};

const isDayEnabled = (days, dayName) => {
  const exact = days[dayName];
  if (typeof exact === 'boolean') return exact;

  const lower = days[dayName.toLowerCase()];
  if (typeof lower === 'boolean') return lower;

  // Backward-compatible fallback: if no day map is stored, keep booking enabled.
  return Object.keys(days).length === 0;
};

const slotConflictsWithBookings = ({
  slotMinutes,
  bookedConsultations,
  localDateKey,
  bookingMinute,
}) =>
  bookedConsultations.some((consultation) => {
    const bookedDate = new Date(consultation.scheduled_at);
    if (getLocalDateKey(bookedDate) !== localDateKey) {
      return false;
    }

    const bookedMinute = getLocalMinutesOfDay(bookedDate);
    return Math.abs(bookedMinute - bookingMinute) < slotMinutes;
  });

const fetchBookedConsultationsForDoctorAndDate = async ({ doctorId, dateString }) => {
  const { startIso, nextDayStartIso } = getUtcDayRangeForLocalDate(dateString);

  const { data, error } = await supabase
    .from('consultations')
    .select('id, scheduled_at, status')
    .eq('doctor_id', doctorId)
    .in('status', ACTIVE_BOOKING_STATUSES)
    .gte('scheduled_at', startIso)
    .lt('scheduled_at', nextDayStartIso);

  if (error) {
    throw error;
  }

  return data || [];
};

const fetchPatientAndDoctorUsers = async ({ patientId, doctorId }) => {
  const [patientResult, doctorResult] = await Promise.all([
    supabase.from('users').select('id, email, full_name').eq('id', patientId).single(),
    supabase.from('users').select('id, email, full_name').eq('id', doctorId).single(),
  ]);

  if (patientResult.error) throw patientResult.error;
  if (doctorResult.error) throw doctorResult.error;

  return {
    patient: patientResult.data,
    doctor: doctorResult.data,
  };
};

const sendScheduleEmailsInternal = async ({
  patientId,
  doctorId,
  scheduledAt,
  consultationId,
  roomCode,
}) => {
  const { patient, doctor } = await fetchPatientAndDoctorUsers({ patientId, doctorId });

  if (!patient?.email || !doctor?.email) {
    throw new Error('Missing email for patient or doctor.');
  }

  const when = new Date(scheduledAt).toLocaleString('en-IN', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  const subject = 'PulseCare Video Consultation Scheduled';
  const jitsiAppKey = process.env.JITSI_APP_KEY || 'vpaas-magic-cookie-default';
  const safeRoomCode = roomCode || (consultationId ? `consult_${consultationId}` : undefined);
  const meetingUrl = safeRoomCode
    ? `https://8x8.vc/${jitsiAppKey}/${safeRoomCode}`
    : null;

  const joinInfo =
    meetingUrl && safeRoomCode
      ? `\n\nRoom code: ${safeRoomCode}\nIf needed, you can also join via this link: ${meetingUrl}`
      : '';

  const patientText = `Hello ${
    patient.full_name || 'Patient'
  },\n\nYour video consultation with Dr. ${
    doctor.full_name || 'Doctor'
  } has been scheduled for ${when}.${joinInfo}\n\nPlease open the PulseCare app at the scheduled time and tap on the consultation to join the video call.\n\nRegards,\nPulseCare Team`;

  const doctorText = `Hello Dr. ${
    doctor.full_name || ''
  },\n\nA new video consultation has been scheduled with patient ${
    patient.full_name || 'Patient'
  } for ${when}.${joinInfo}\n\nPlease open the PulseCare app at the scheduled time and start the video call from your consultations list.\n\nRegards,\nPulseCare Team`;

  await Promise.all([
    sendTextEmail({
      to: patient.email,
      subject,
      text: patientText,
    }),
    sendTextEmail({
      to: doctor.email,
      subject,
      text: doctorText,
    }),
  ]);

  return {
    patientEmail: patient.email,
    doctorEmail: doctor.email,
  };
};

const fetchDoctorProfile = async (doctorId) => {
  const { data, error } = await supabase
    .from('doctors')
    .select('id, consultation_fee, availability')
    .eq('id', doctorId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
};

exports.getDoctorAvailability = async (req, res) => {
  const { doctorId } = req.params;

  if (!doctorId) {
    return res.status(400).json({ error: 'doctorId is required.' });
  }

  try {
    const doctor = await fetchDoctorProfile(doctorId);
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found.' });
    }

    const normalized = normalizeAvailability(doctor.availability);
    return res.json({
      doctorId,
      consultationFee: doctor.consultation_fee,
      availability: {
        ...doctor.availability,
        start_time: formatMinutesAsTime(normalized.startMinutes),
        end_time: formatMinutesAsTime(normalized.endMinutes),
        slot_minutes: normalized.slotMinutes,
      },
    });
  } catch (err) {
    console.error('[ConsultationController] getDoctorAvailability error:', err.message || err);
    return res.status(500).json({ error: 'Failed to fetch doctor availability.' });
  }
};

exports.getDoctorAvailableSlots = async (req, res) => {
  const { doctorId } = req.params;
  const { date } = req.query;

  if (!doctorId || !date || !isValidDateString(date)) {
    return res.status(400).json({ error: 'doctorId and valid date (YYYY-MM-DD) are required.' });
  }

  try {
    const doctor = await fetchDoctorProfile(doctorId);
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found.' });
    }

    const availability = normalizeAvailability(doctor.availability);
    const { year, month, day } = parseDateString(date);
    const dayName = DAY_NAMES[new Date(Date.UTC(year, month - 1, day)).getUTCDay()];

    if (!isDayEnabled(availability.days, dayName)) {
      return res.json({ date, slots: [] });
    }

    if (availability.endMinutes <= availability.startMinutes) {
      return res.json({ date, slots: [] });
    }

    const bookedConsultations = await fetchBookedConsultationsForDoctorAndDate({
      doctorId,
      dateString: date,
    });

    const now = new Date();
    const todayKey = getLocalDateKey(now);
    const nowMinutes = getLocalMinutesOfDay(now);

    const slots = [];
    for (
      let minute = availability.startMinutes;
      minute + availability.slotMinutes <= availability.endMinutes;
      minute += availability.slotMinutes
    ) {
      const isInPastToday = date === todayKey && minute <= nowMinutes;
      if (isInPastToday) {
        continue;
      }

      const hasConflict = slotConflictsWithBookings({
        slotMinutes: availability.slotMinutes,
        bookedConsultations,
        localDateKey: date,
        bookingMinute: minute,
      });

      if (hasConflict) {
        continue;
      }

      const hour = Math.floor(minute / 60);
      const minuteOfHour = minute % 60;
      const scheduledAtUtc = localDateTimeToUtcDate({
        year,
        month,
        day,
        hour,
        minute: minuteOfHour,
      });

      slots.push({
        time: formatMinutesAsTime(minute),
        scheduled_at: scheduledAtUtc.toISOString(),
      });
    }

    return res.json({ date, slots });
  } catch (err) {
    console.error('[ConsultationController] getDoctorAvailableSlots error:', err.message || err);
    return res.status(500).json({ error: 'Failed to fetch available slots.' });
  }
};

exports.createConsultation = async (req, res) => {
  const { patientId, doctorId, scheduledAt, fee, symptoms } = req.body || {};

  if (!patientId || !doctorId || !scheduledAt || fee == null) {
    return res.status(400).json({
      error: 'patientId, doctorId, scheduledAt and fee are required.',
    });
  }

  const scheduledDate = new Date(scheduledAt);
  if (Number.isNaN(scheduledDate.getTime())) {
    return res.status(400).json({ error: 'Invalid scheduledAt date.' });
  }

  try {
    const doctor = await fetchDoctorProfile(doctorId);
    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found.' });
    }

    const availability = normalizeAvailability(doctor.availability);
    const localDateKey = getLocalDateKey(scheduledDate);
    const weekday = getLocalWeekday(scheduledDate);
    const minuteOfDay = getLocalMinutesOfDay(scheduledDate);

    if (!isDayEnabled(availability.days, weekday)) {
      return res.status(400).json({
        error: `Doctor is not available on ${weekday}.`,
      });
    }

    if (
      minuteOfDay < availability.startMinutes ||
      minuteOfDay + availability.slotMinutes > availability.endMinutes
    ) {
      return res.status(400).json({
        error: 'Selected time is outside doctor availability hours.',
      });
    }

    const bookedConsultations = await fetchBookedConsultationsForDoctorAndDate({
      doctorId,
      dateString: localDateKey,
    });

    const hasConflict = slotConflictsWithBookings({
      slotMinutes: availability.slotMinutes,
      bookedConsultations,
      localDateKey,
      bookingMinute: minuteOfDay,
    });

    if (hasConflict) {
      return res.status(409).json({
        error: 'Selected slot is already booked. Please choose another time.',
      });
    }

    // Ensure patient profile exists for consultations.patient_id foreign key.
    const existingPatient = await supabase
      .from('patients')
      .select('id')
      .eq('id', patientId)
      .maybeSingle();

    if (existingPatient.error) {
      throw existingPatient.error;
    }

    if (!existingPatient.data) {
      const { error: insertPatientError } = await supabase.from('patients').insert({
        id: patientId,
        gender: 'Not specified',
      });

      if (insertPatientError) {
        throw insertPatientError;
      }
    }

    const roomCode = `consult_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    const { data: insertedConsultation, error: insertConsultError } = await supabase
      .from('consultations')
      .insert({
        patient_id: patientId,
        doctor_id: doctorId,
        scheduled_at: scheduledDate.toISOString(),
        fee: Number(fee),
        symptoms: symptoms || null,
        status: 'scheduled',
        room_code: roomCode,
      })
      .select('*')
      .single();

    if (insertConsultError) {
      throw insertConsultError;
    }

    let emailSent = true;
    let emailError = null;

    try {
      await sendScheduleEmailsInternal({
        patientId,
        doctorId,
        scheduledAt: insertedConsultation.scheduled_at,
        consultationId: insertedConsultation.id,
        roomCode: insertedConsultation.room_code,
      });
    } catch (mailErr) {
      emailSent = false;
      emailError = mailErr.message || 'Failed to send schedule emails.';
      console.error('[ConsultationController] createConsultation email error:', mailErr);
    }

    return res.status(201).json({
      success: true,
      consultation: insertedConsultation,
      emailSent,
      emailError,
    });
  } catch (err) {
    console.error('[ConsultationController] createConsultation error:', err.message || err);
    return res.status(500).json({ error: 'Failed to create consultation.' });
  }
};

exports.getConsultations = async (req, res) => {
  const { userId } = req.query;

  if (!userId) {
    return res.status(400).json({ error: 'userId query parameter is required.' });
  }

  try {
    const { data: consultations, error: consultationsError } = await supabase
      .from('consultations')
      .select('*')
      .or(`patient_id.eq.${userId},doctor_id.eq.${userId}`)
      .order('scheduled_at', { ascending: true });

    if (consultationsError) {
      throw consultationsError;
    }

    const records = consultations || [];
    const doctorIds = [...new Set(records.map((item) => item.doctor_id).filter(Boolean))];
    const patientIds = [...new Set(records.map((item) => item.patient_id).filter(Boolean))];

    let doctorProfiles = [];
    if (doctorIds.length > 0) {
      const doctorResult = await supabase
        .from('doctors')
        .select('id, specialization, consultation_fee, users(full_name, email)')
        .in('id', doctorIds);

      if (doctorResult.error) {
        throw doctorResult.error;
      }
      doctorProfiles = doctorResult.data || [];
    }

    let patientUsers = [];
    if (patientIds.length > 0) {
      const patientResult = await supabase
        .from('users')
        .select('id, full_name, email')
        .in('id', patientIds);

      if (patientResult.error) {
        throw patientResult.error;
      }
      patientUsers = patientResult.data || [];
    }

    const doctorMap = doctorProfiles.reduce((acc, item) => {
      acc[item.id] = item;
      return acc;
    }, {});

    const patientMap = patientUsers.reduce((acc, item) => {
      acc[item.id] = item;
      return acc;
    }, {});

    const enriched = records.map((item) => ({
      ...item,
      doctor: doctorMap[item.doctor_id] || null,
      patient: patientMap[item.patient_id]
        ? {
            id: patientMap[item.patient_id].id,
            full_name: patientMap[item.patient_id].full_name,
            email: patientMap[item.patient_id].email,
          }
        : null,
    }));

    return res.json(enriched);
  } catch (err) {
    console.error('[ConsultationController] getConsultations error:', err.message || err);
    return res.status(500).json({ error: 'Failed to fetch consultations.' });
  }
};

exports.updateConsultation = async (req, res) => {
  const { id } = req.params;
  const { status, notes, prescription } = req.body || {};

  if (!id) {
    return res.status(400).json({ error: 'Consultation id is required.' });
  }

  const updateData = {};
  if (status != null) {
    const allowedStatuses = ['scheduled', 'ongoing', 'completed', 'cancelled'];
    if (!allowedStatuses.includes(status)) {
      return res.status(400).json({
        error: `Invalid status. Allowed values: ${allowedStatuses.join(', ')}`,
      });
    }
    updateData.status = status;
  }

  if (notes != null) {
    updateData.notes = notes;
  }

  if (prescription != null) {
    updateData.prescription = prescription;
  }

  if (Object.keys(updateData).length === 0) {
    return res.status(400).json({ error: 'No fields provided for update.' });
  }

  try {
    const { data, error } = await supabase
      .from('consultations')
      .update(updateData)
      .eq('id', id)
      .select('*')
      .single();

    if (error) {
      throw error;
    }

    return res.json({ success: true, consultation: data });
  } catch (err) {
    console.error('[ConsultationController] updateConsultation error:', err.message || err);
    return res.status(500).json({ error: 'Failed to update consultation.' });
  }
};

exports.sendScheduleEmails = async (req, res) => {
  const { patientId, doctorId, scheduledAt, consultationId, roomCode } =
    req.body || {};

  if (!patientId || !doctorId || !scheduledAt) {
    return res.status(400).json({
      error: 'patientId, doctorId and scheduledAt are required.',
    });
  }

  try {
    const result = await sendScheduleEmailsInternal({
      patientId,
      doctorId,
      scheduledAt,
      consultationId,
      roomCode,
    });

    console.log(
      `[ConsultationController] Schedule emails sent to ${result.patientEmail} and ${result.doctorEmail}`,
    );
    return res.json({ success: true });
  } catch (err) {
    console.error('[ConsultationController] sendScheduleEmails error:', err.message || err);
    return res.status(500).json({ error: 'Failed to send schedule emails.' });
  }
};
