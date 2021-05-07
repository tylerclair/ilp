-- ***** USU MOD START
--           sectn.SSBSECT_LEARNER_REGSTART_TDATE,
CASE
    WHEN sectn.SSBSECT_PTRM_END_DATE IS NULL
    THEN
          (sectn.SSBSECT_LEARNER_REGSTART_TDATE - 1)
        + (  sectn.SSBSECT_NUMBER_OF_UNITS
           * DECODE (sectn.SSBSECT_DUNT_CODE,
                     'DAY', 1,
                     'MTHS', 31,
                     'SEM', 120,
                     'WEEK', 7))
    ELSE
        sectn.SSBSECT_LEARNER_REGSTART_TDATE
END    AS SECTION_END_DATE,
-- ***** USU MOD END
