CREATE OR REPLACE PACKAGE BODY BANINST1.z_canvas_extracts
AS
   FUNCTION f_enclose (p_string IN OUT VARCHAR2)
      RETURN VARCHAR2
   IS
      quot   CHAR := CHR (34);                 --ASCII character double quotes
   BEGIN
      IF p_string IS NULL
      THEN
         RETURN NULL;
      ELSE
         RETURN (quot || p_string || quot);
      END IF;
   END;

   FUNCTION f_get_email (p_pidm IN NUMBER)
      RETURN VARCHAR2
   IS
      v_emal_code       goremal.goremal_emal_code%TYPE := NULL;
      v_preferred_ind   VARCHAR2 (1) := 'Y';

      CURSOR get_email
      IS
         SELECT MAX (goremal_email_address) email
           FROM goremal
          WHERE     goremal_preferred_ind = v_preferred_ind
                AND goremal_status_ind = 'A'
                AND (goremal_emal_code = v_emal_code OR v_emal_code IS NULL)
                AND goremal_pidm = p_pidm;

      email_rec         get_email%ROWTYPE;
   BEGIN
      email_rec := NULL;

      OPEN get_email;

      FETCH get_email INTO email_rec;

      CLOSE get_email;

      IF email_rec.email IS NULL
      THEN
         v_preferred_ind := 'N';
         v_emal_code := 'MCCM';

         OPEN get_email;

         FETCH get_email INTO email_rec;

         CLOSE get_email;
      END IF;

      RETURN email_rec.email;
   END f_get_email;

   FUNCTION f_get_account_id (p_crn IN VARCHAR2, p_term IN VARCHAR2)
      RETURN VARCHAR2
   IS
      CURSOR get_subject
      IS
         SELECT ssbsect_subj_code subject, ssbsect_crse_numb crse
           FROM ssbsect
          WHERE ssbsect_crn = p_crn AND ssbsect_term_code = p_term;

      subject_rec   get_subject%ROWTYPE;

      CURSOR get_account_id
      IS
           SELECT 'DEP' || a.scbcrse_dept_code dept_code
             FROM scbcrse a
            WHERE     a.scbcrse_eff_term =
                         (SELECT MAX (b.scbcrse_eff_term)
                            FROM scbcrse b
                           WHERE     b.scbcrse_eff_term <= p_term
                                 AND b.scbcrse_subj_code = a.scbcrse_subj_code
                                 AND b.scbcrse_crse_numb = a.scbcrse_crse_numb)
                  AND a.scbcrse_subj_code = subject_rec.subject
                  AND a.scbcrse_crse_numb = subject_rec.crse
         GROUP BY a.scbcrse_dept_code;

      account_rec   get_account_id%ROWTYPE;
   BEGIN
      subject_rec := NULL;

      OPEN get_subject;

      FETCH get_subject INTO subject_rec;

      CLOSE get_subject;

      account_rec := NULL;

      OPEN get_account_id;

      FETCH get_account_id INTO account_rec;

      CLOSE get_account_id;

      IF account_rec.dept_code IS NULL
      THEN
         account_rec.dept_code := 'DEPXXXX';
      END IF;

      RETURN account_rec.dept_code;
   END f_get_account_id;

   PROCEDURE process_jobsub (one_up_no IN gjbprun.gjbprun_one_up_no%TYPE)
   IS
      v_term                  VARCHAR2 (6);
      v_run_terms             VARCHAR2 (1);
      v_run_users_student     VARCHAR2 (1);
      v_run_users_employee    VARCHAR2 (1);
      v_run_accounts          VARCHAR2 (1);
      v_run_courses           VARCHAR2 (1);
      v_run_sections          VARCHAR2 (1);
      v_run_enrollments       VARCHAR2 (1);
      v_run_xlist             VARCHAR2 (1);
      v_run_preferred_names   VARCHAR2 (1);
   BEGIN
      v_term := z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '01');
      v_run_terms :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '02');
      v_run_users_student :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '03');
      v_run_users_employee :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '04');
      v_run_accounts :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '05');
      v_run_courses :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '06');
      v_run_sections :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '07');
      v_run_enrollments :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '08');
      v_run_xlist :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '09');
      v_run_preferred_names :=
         z_jobsub_utility.get_jobsub_parm ('ZCANVAS', one_up_no, '10');

      p_run_canvas_extracts (v_term,
                             v_run_terms,
                             v_run_users_student,
                             v_run_users_employee,
                             v_run_accounts,
                             v_run_courses,
                             v_run_sections,
                             v_run_enrollments,
                             v_run_xlist,
                             v_run_preferred_names);

      -- delete the job submission parameters
      z_jobsub_utility.clean_up_parms ('ZCANVAS', one_up_no);
      COMMIT;
   END;

   PROCEDURE p_error (error_message IN VARCHAR2)
   IS
   BEGIN
      DBMS_OUTPUT.PUT_LINE (error_message);
   END p_error;

   PROCEDURE p_run_canvas_extracts (
      p_term                  IN VARCHAR2 DEFAULT '201140',
      p_run_terms             IN VARCHAR2 DEFAULT 'Y',
      p_run_users_student     IN VARCHAR2 DEFAULT 'Y',
      p_run_users_employee    IN VARCHAR2 DEFAULT 'Y',
      p_run_accounts          IN VARCHAR2 DEFAULT 'Y',
      p_run_courses           IN VARCHAR2 DEFAULT 'Y',
      p_run_sections          IN VARCHAR2 DEFAULT 'Y',
      p_run_enrollments       IN VARCHAR2 DEFAULT 'Y',
      p_run_xlist             IN VARCHAR2 DEFAULT 'Y',
      p_run_preferred_names   IN VARCHAR2 DEFAULT 'Y')
   IS
   BEGIN
      IF UPPER (p_run_terms) = 'Y'
      THEN
         p_canvas_terms;
      END IF;

      IF UPPER (p_run_users_student) = 'Y'
      THEN
         p_canvas_users_student (p_term);
      END IF;

      IF UPPER (p_run_users_student) = 'Y'
      THEN
         p_canvas_users_employee (p_term);
      END IF;

      IF UPPER (p_run_accounts) = 'Y'
      THEN
         p_accounts (p_term);
      END IF;

      IF UPPER (p_run_courses) = 'Y'
      THEN
         p_course_info (p_term);
      END IF;

      IF UPPER (p_run_sections) = 'Y'
      THEN
         p_section_info (p_term);
      END IF;

      IF UPPER (p_run_enrollments) = 'Y'
      THEN
         p_enrollment (p_term);
      END IF;

      IF UPPER (p_run_xlist) = 'Y'
      THEN
         p_xlist (p_term);
      END IF;

      IF UPPER (p_run_preferred_names) = 'Y'
      THEN
         p_preferred_names ();
      END IF;

   END p_run_canvas_extracts;

   PROCEDURE p_write_file (file_header       IN VARCHAR2,
                           file_data_array   IN record_table,
                           file_name         IN VARCHAR2)
   IS
      v_ID            UTL_FILE.FILE_TYPE;
      v_file_access   VARCHAR2 (1) := 'w';
      v_folder        VARCHAR2 (30) := 'BLACKBOARD';
      index_count     PLS_INTEGER := 0;
   BEGIN
      v_ID := UTL_FILE.FOPEN (v_folder, file_name, v_file_access);

      UTL_FILE.PUT_LINE (v_ID, file_header);

      FOR index_count IN file_data_array.FIRST .. file_data_array.LAST
      LOOP
         UTL_FILE.PUT_LINE (v_ID, file_data_array (index_count));
      --DBMS_OUTPUT.PUT_LINE(file_data_array(index_count));

      END LOOP;

      UTL_FILE.FCLOSE (v_ID);
   END p_write_file;


   PROCEDURE p_sourced_id (p_source_pidm   IN     NUMBER,
                           p_sourced_id       OUT VARCHAR2)
   IS
      CURSOR get_sourced_id
      IS
         SELECT gobsrid_sourced_id sourced_id
           FROM gobsrid
          WHERE gobsrid_pidm = p_source_pidm;

      sourced_id_rec   get_sourced_id%ROWTYPE;
   BEGIN
      OPEN get_sourced_id;

      FETCH get_sourced_id INTO sourced_id_rec.sourced_id;

      CLOSE get_sourced_id;

      IF sourced_id_rec.sourced_id IS NULL
      THEN
         p_sourced_id := 'No ID';
      ELSE
         p_sourced_id := sourced_id_rec.sourced_id;
      END IF;
   END p_sourced_id;


   PROCEDURE p_get_section_id (p_crn          IN     VARCHAR2,
                               p_term         IN     VARCHAR2,
                               p_section_id      OUT VARCHAR2)
   IS
   BEGIN
      p_section_id := p_crn || '.' || p_term;
   END p_get_section_id;


   PROCEDURE p_get_course_id (p_crn         IN     VARCHAR2,
                              p_term        IN     VARCHAR2,
                              p_course_id      OUT VARCHAR2)
   IS
      CURSOR get_course_id
      IS
         SELECT    'CCRS'
                || ssbsect_subj_code
                || '-'
                || ssbsect_crse_numb
                || '-'
                || ssbsect_crn
                || '.'
                || ssbsect_term_code
                   course_id
           FROM ssbsect
          WHERE ssbsect_crn = p_crn AND ssbsect_term_code = p_term;

      course_id_rec   get_course_id%ROWTYPE;
   BEGIN
      OPEN get_course_id;

      FETCH get_course_id INTO p_course_id;

      CLOSE get_course_id;
   END p_get_course_id;


   PROCEDURE p_canvas_terms
   IS
      v_file_name    VARCHAR2 (30) := 'terms.csv';
      record_count   PLS_INTEGER := 0;
      v_delim        VARCHAR2 (1) := CHR (44);
      term_status    VARCHAR2 (20) := 'active';

      file_array     record_table;
      file_header    VARCHAR2 (100)
                        := 'term_id,name,status,start_date,end_date';
      ERR_MSG        VARCHAR2 (250);

      CURSOR get_terms
      IS
           SELECT MAX (stvterm_code) term_code,
                  stvterm_desc term_desc,
                  TO_CHAR (stvterm_start_date, 'YYYY-mm-DD HH:MM:SS')
                     start_date,
                  TO_CHAR (stvterm_end_date, 'YYYY-mm-DD HH:MM:SS') end_date
             FROM stvterm
            WHERE     SYSDATE BETWEEN stvterm_start_date AND stvterm_end_date
                  AND stvterm_code != '999999'
                  AND SUBSTR (stvterm_code, 5, 2) IN ('20', '30', '40')
         GROUP BY stvterm_desc, stvterm_start_date, stvterm_end_date
         ORDER BY 1;

      term_rec       get_terms%ROWTYPE;
   BEGIN
      OPEN get_terms;

      LOOP
         BEGIN
            term_rec := NULL;

            FETCH get_terms INTO term_rec;

            EXIT WHEN get_terms%NOTFOUND;

            record_count := record_count + 1;

            file_array (record_count) :=
                  term_rec.term_code
               || v_delim
               || term_rec.term_desc
               || v_delim
               || term_status
               || v_delim
               || term_rec.start_date
               || v_delim
               || term_rec.end_date;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_terms;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Terms Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Terms Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_canvas_terms;


   PROCEDURE p_canvas_users_student (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name     VARCHAR2 (30) := 'users_student.csv';
      record_count    PLS_INTEGER := 0;
      file_header     VARCHAR2 (100)
         := 'user_id,login_id,last_name,first_name,email,status';
      file_array      record_table;

      v_delim         VARCHAR2 (1) := CHR (44);
      email_address   goremal.goremal_email_address%TYPE;
      status          VARCHAR2 (8) := 'active';
      sourced_id      VARCHAR2 (16);
      ERR_MSG         VARCHAR2 (250);

      CURSOR get_pidm
      IS
           SELECT sfrstcr_pidm pidm
             FROM stvrsts, sfrstcr
            WHERE     stvrsts_incl_sect_enrl = 'Y'
                  AND stvrsts_code = sfrstcr_rsts_code
                  AND sfrstcr_term_code = term_in
         GROUP BY sfrstcr_pidm;

      pidm_rec        get_pidm%ROWTYPE;

      CURSOR get_name
      IS
         SELECT spriden_id a_number,
                spriden_first_name first_name,
                spriden_last_name last_name
           FROM spriden
          WHERE spriden_change_ind IS NULL AND spriden_pidm = pidm_rec.pidm;

      name_rec        get_name%ROWTYPE;
   BEGIN
      OPEN get_pidm;

      LOOP
         BEGIN
            FETCH get_pidm INTO pidm_rec;

            --EXIT WHEN record_count = 200;
            EXIT WHEN get_pidm%NOTFOUND;

            record_count := record_count + 1;

            name_rec := NULL;

            OPEN get_name;

            FETCH get_name INTO name_rec;

            CLOSE get_name;

            email_address := f_get_email (pidm_rec.pidm);

            p_sourced_id (pidm_rec.pidm, sourced_id);

            file_array (record_count) :=
                  sourced_id
               || v_delim
               || name_rec.a_number
               || v_delim
               || name_rec.last_name
               || v_delim
               || name_rec.first_name
               || v_delim
               || email_address
               || v_delim
               || status;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_pidm;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Users Student Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Users Student Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_canvas_users_student;

   PROCEDURE p_canvas_users_employee (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name     VARCHAR2 (30) := 'users_emp.csv';
      record_count    PLS_INTEGER := 0;
      file_header     VARCHAR2 (100)
         := 'user_id,login_id,last_name,first_name,email,status';
      file_array      record_table;

      v_delim         VARCHAR2 (1) := CHR (44);
      email_address   goremal.goremal_email_address%TYPE;
      status          VARCHAR2 (8) := 'active';
      sourced_id      VARCHAR2 (16);
      ERR_MSG         VARCHAR2 (250);

      CURSOR get_employee
      IS
           SELECT ID a_number, last_name, first_name
             FROM z_ap_job_detail
            WHERE job_number LIKE '9%'
         GROUP BY ID, last_name, first_name;

      employee_rec    get_employee%ROWTYPE;

      CURSOR get_pidm
      IS
         SELECT spriden_pidm pidm
           FROM spriden
          WHERE     spriden_change_ind IS NULL
                AND spriden_id = employee_rec.a_number;

      pidm_rec        get_pidm%ROWTYPE;
   BEGIN
      OPEN get_employee;

      LOOP
         BEGIN
            FETCH get_employee INTO employee_rec;

            EXIT WHEN get_employee%NOTFOUND;

            record_count := record_count + 1;

            pidm_rec := NULL;

            OPEN get_pidm;

            FETCH get_pidm INTO pidm_rec;

            CLOSE get_pidm;

            email_address := f_get_email (pidm_rec.pidm);

            p_sourced_id (pidm_rec.pidm, sourced_id);

            file_array (record_count) :=
                  sourced_id
               || v_delim
               || employee_rec.a_number
               || v_delim
               || employee_rec.last_name
               || v_delim
               || employee_rec.first_name
               || v_delim
               || email_address
               || v_delim
               || status;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_employee;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG :=
            'ERR Users Employee Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG :=
            'ERR Users Employee Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_canvas_users_employee;


   PROCEDURE p_accounts (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name    VARCHAR2 (30) := 'accounts.csv';
      record_count   PLS_INTEGER := 0;
      file_header    VARCHAR2 (100)
                        := 'account_id,parent_account_id,name,status';
      file_array     record_table;
      v_delim        VARCHAR2 (1) := CHR (44);
      v_status       VARCHAR2 (20) := 'active';
      ERR_MSG        VARCHAR2 (250);

      CURSOR get_accounts
      IS
         SELECT 'DEP' || stvdept_code dep_code,
                '"' || stvdept_desc || '"' dep_desc
           FROM stvdept
         UNION
         SELECT 'COL' || stvcoll_code dep_code,
                '"' || stvcoll_desc || '"' dep_desc
           FROM stvcoll;

      accounts_rec   get_accounts%ROWTYPE;

      CURSOR get_parent
      IS
         SELECT 'COL' || a.scbcrse_coll_code parent_id
           FROM scbcrse a
          WHERE     'DEP' || a.scbcrse_dept_code = accounts_rec.dep_code
                AND a.scbcrse_eff_term =
                       (SELECT MAX (b.scbcrse_eff_term)
                          FROM scbcrse b
                         WHERE     b.scbcrse_subj_code = a.scbcrse_subj_code
                               AND b.scbcrse_crse_numb = a.scbcrse_crse_numb
                               AND b.scbcrse_eff_term <= term_in);


      parent_rec     get_parent%ROWTYPE;
   BEGIN
      OPEN get_accounts;

      LOOP
         BEGIN
            FETCH get_accounts INTO accounts_rec;

            EXIT WHEN get_accounts%NOTFOUND;

            record_count := record_count + 1;

            IF SUBSTR (accounts_rec.dep_code, 1, 3) = 'DEP'
            THEN
               parent_rec := NULL;

               OPEN get_parent;

               FETCH get_parent INTO parent_rec;

               CLOSE get_parent;
            END IF;

            file_array (record_count) :=
                  accounts_rec.dep_code
               || v_delim
               || parent_rec.parent_id
               || v_delim
               || accounts_rec.dep_desc
               || v_delim
               || v_status;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_accounts;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Accounts Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Accounts Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_accounts;

   PROCEDURE p_course_info (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name    VARCHAR2 (30) := 'courses.csv';
      record_count   PLS_INTEGER := 0;
      file_header    VARCHAR2 (100)
         := 'course_id,short_name,long_name,account_id,term_id,status';
      file_array     record_table;
      v_delim        VARCHAR2 (1) := CHR (44);
      v_status       VARCHAR2 (20) := 'active';
      course_id      VARCHAR2 (45);
      account_id     VARCHAR2 (20);
      ERR_MSG        VARCHAR2 (250);

      CURSOR get_course_info
      IS
           SELECT a.scbcrse_subj_code subject,
                  a.scbcrse_crse_numb crse,
                  a.scbcrse_subj_code || '-' || a.scbcrse_crse_numb short_name,
                  '"' || a.scbcrse_title || '"' long_name
             FROM stvsubj, scbcrse a, ssbsect
            WHERE     stvsubj_code(+) = a.scbcrse_subj_code
                  AND a.scbcrse_eff_term =
                         (SELECT MAX (b.scbcrse_eff_term)
                            FROM stvsubj, scbcrse b
                           WHERE     b.scbcrse_eff_term >= term_in
                                 AND b.scbcrse_subj_code = a.scbcrse_subj_code
                                 AND b.scbcrse_crse_numb = a.scbcrse_crse_numb)
                  AND a.scbcrse_subj_code = ssbsect_subj_code
                  AND a.scbcrse_crse_numb = ssbsect_crse_numb
                  AND ssbsect_term_code = term_in
         GROUP BY a.scbcrse_subj_code,
                  a.scbcrse_crse_numb,
                  a.scbcrse_title,
                  a.scbcrse_dept_code;

      course_rec     get_course_info%ROWTYPE;

      CURSOR get_crn
      IS
         SELECT MAX (ssbsect_crn) crn
           FROM ssbsect
          WHERE     ssbsect_subj_code = course_rec.subject
                AND ssbsect_crse_numb = course_rec.crse
                AND ssbsect_term_code = term_in;

      crn_rec        get_crn%ROWTYPE;


      CURSOR get_date_info
      IS
         SELECT stvterm_code term_id,
                stvterm_start_date start_date,
                stvterm_end_date end_date
           FROM stvterm
          WHERE stvterm_code = term_in;

      date_rec       get_date_info%ROWTYPE;
   BEGIN
      OPEN get_date_info;

      FETCH get_date_info INTO date_rec;

      CLOSE get_date_info;

      OPEN get_course_info;

      LOOP
         BEGIN
            FETCH get_course_info INTO course_rec;

            EXIT WHEN get_course_info%NOTFOUND;

            record_count := record_count + 1;

            OPEN get_crn;

            FETCH get_crn INTO crn_rec;

            CLOSE get_crn;

            p_get_course_id (crn_rec.crn, term_in, course_id);
            account_id := f_get_account_id (crn_rec.crn, term_in);

            file_array (record_count) :=
                  course_id
               || v_delim
               || course_rec.short_name
               || v_delim
               || course_rec.long_name
               || v_delim
               || account_id
               || v_delim
               || date_rec.term_id
               || v_delim
               || v_status;
            --|| v_delim
            --|| date_rec.start_date
            --|| v_delim
            --|| date_rec.end_date;

            p_write_file (file_header, file_array, v_file_name);
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_course_info;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Course Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Course Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_course_info;

   PROCEDURE p_section_info (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name    VARCHAR2 (30) := 'sections.csv';
      record_count   PLS_INTEGER := 0;
      file_header    VARCHAR2 (100)
         := 'section_id,course_id,name,status,start_date,end_date,account_id';
      file_array     record_table;
      v_delim        VARCHAR2 (1) := CHR (44);
      section_id     VARCHAR2 (20);
      course_id      VARCHAR2 (45);
      account_id     VARCHAR2 (20);
      v_status       VARCHAR2 (20) := 'active';
      ERR_MSG        VARCHAR2 (250);

      CURSOR term_desc
      IS
         SELECT DECODE (SUBSTR (term_in, 5, 2),
                        '20', 'Sp',
                        '30', 'Su',
                        '40', 'Fa')
                   t_desc,
                SUBSTR (term_in, 3, 2) t_year
           FROM DUAL;

      term_rec       term_desc%ROWTYPE;


      CURSOR get_section
      IS
         SELECT ssbsect_crn crn,
                ssbsect_subj_code subject,
                ssbsect_crse_numb crse,
                   ssbsect_subj_code
                || '-'
                || ssbsect_crse_numb
                || '-'
                || ssbsect_seq_numb
                   sect_name,
                ssbsect_ptrm_start_date start_date,
                ssbsect_ptrm_end_date end_date
           FROM ssbsect
          WHERE ssbsect_term_code = term_in;

      section_rec    get_section%ROWTYPE;

      CURSOR get_section_alt
      IS
         SELECT MIN (ssrmeet_start_date) start_date,
                MAX (ssrmeet_end_date) end_date
           FROM ssrmeet
          WHERE ssrmeet_term_code = term_in AND ssrmeet_crn = section_rec.crn;

      CURSOR get_term_dates
      IS
         SELECT stvterm_start_date, stvterm_end_date
           FROM stvterm
          WHERE stvterm_code = term_in;
   BEGIN
      OPEN get_section;

      LOOP
         BEGIN
            term_rec := NULL;

            OPEN term_desc;

            FETCH term_desc INTO term_rec;

            CLOSE term_desc;

            section_rec := NULL;

            FETCH get_section INTO section_rec;

            EXIT WHEN get_section%NOTFOUND;

            record_count := record_count + 1;

            IF section_rec.start_date IS NULL
            THEN
               OPEN get_section_alt;

               FETCH get_section_alt
                  INTO section_rec.start_date, section_rec.end_date;

               CLOSE get_section_alt;
            END IF;

            IF section_rec.start_date IS NULL
            THEN
               OPEN get_term_dates;

               FETCH get_term_dates
                  INTO section_rec.start_date, section_rec.end_date;

               CLOSE get_term_dates;
            END IF;

            account_id := NULL;

            section_rec.sect_name :=
                  term_rec.t_desc
               || term_rec.t_year
               || ' '
               || section_rec.sect_name;
            p_get_section_id (section_rec.crn, term_in, section_id);
            p_get_course_id (section_rec.crn, term_in, course_id);
            account_id := f_get_account_id (section_rec.crn, term_in);

            file_array (record_count) :=
                  section_id
               || v_delim
               || course_id
               || v_delim
               || section_rec.sect_name
               || v_delim
               || v_status
               || v_delim
               || section_rec.start_date
               || v_delim
               || section_rec.end_date
               || v_delim
               || account_id;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_section;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Section Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Section Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_section_info;

   PROCEDURE p_enrollment (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name      VARCHAR2 (30) := 'enrollments.csv';
      record_count     PLS_INTEGER := 0;
      file_header      VARCHAR2 (100)
                          := 'course_id,user_id,role,section_id,status';
      file_array       record_table;
      v_delim          VARCHAR2 (1) := CHR (44);
      sourced_id       VARCHAR2 (16);
      course_id        VARCHAR2 (45);
      section_id       VARCHAR2 (20);
      v_status         VARCHAR2 (20) := 'active';
      ERR_MSG          VARCHAR2 (250);

      CURSOR get_enrollment
      IS
         SELECT sfrstcr_pidm pidm, sfrstcr_crn crn, 'student' role
           FROM stvrsts, sfrstcr
          WHERE     stvrsts_incl_sect_enrl = 'Y'
                AND stvrsts_code = sfrstcr_rsts_code
                AND sfrstcr_term_code = term_in
         UNION
         SELECT sirasgn_pidm pidm, sirasgn_crn crn, 'teacher'
           FROM sirasgn
          WHERE sirasgn_term_code = term_in;

      enrollment_rec   get_enrollment%ROWTYPE;
   BEGIN
      OPEN get_enrollment;

      LOOP
         BEGIN
            enrollment_rec := NULL;

            FETCH get_enrollment INTO enrollment_rec;

            EXIT WHEN get_enrollment%NOTFOUND;

            record_count := record_count + 1;

            p_sourced_id (enrollment_rec.pidm, sourced_id);
            p_get_section_id (enrollment_rec.crn, term_in, section_id);
            p_get_course_id (enrollment_rec.crn, term_in, course_id);

            file_array (record_count) :=
                  course_id
               || v_delim
               || sourced_id
               || v_delim
               || enrollment_rec.role
               || v_delim
               || section_id
               || v_delim
               || v_status;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_enrollment;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Enrollment Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Enrollment Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_enrollment;

   PROCEDURE p_xlist (term_in IN VARCHAR2 DEFAULT '201140')
   IS
      v_file_name    VARCHAR2 (30) := 'xlists.csv';
      record_count   PLS_INTEGER := 0;
      file_header    VARCHAR2 (100) := 'xlist_course_id,section_id,status';
      file_array     record_table;
      v_delim        VARCHAR2 (1) := CHR (44);
      v_status       VARCHAR2 (20) := 'active';
      section_id     VARCHAR2 (15);
      ERR_MSG        VARCHAR2 (250);

      CURSOR get_xlist
      IS
         SELECT 'XXLS' || ssrxlst_xlst_group || ssbsect_term_code
                   xlist_course_id,
                ssbsect_crn crn
           FROM ssbsect, ssrxlst
          WHERE     ssbsect_term_code = ssrxlst_term_code
                AND ssbsect_crn = ssrxlst_crn
                AND ssrxlst_term_code = term_in;


      xlist_rec      get_xlist%ROWTYPE;
   BEGIN
      OPEN get_xlist;

      LOOP
         BEGIN
            xlist_rec := NULL;

            FETCH get_xlist INTO xlist_rec;

            EXIT WHEN get_xlist%NOTFOUND;

            record_count := record_count + 1;

            p_get_section_id (xlist_rec.crn, term_in, section_id);

            file_array (record_count) :=
                  xlist_rec.xlist_course_id
               || v_delim
               || section_id
               || v_delim
               || v_status;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_xlist;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Xlist Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Xlist Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_xlist;

   PROCEDURE p_preferred_names
   IS
      v_file_name    VARCHAR2 (30) := 'names.csv';
      record_count   PLS_INTEGER := 0;
      file_header    VARCHAR2 (100)
         := 'user_id,login_id,first_name,last_name,sortable_name,short_name,status';
      file_array     record_table;
      v_delim        VARCHAR2 (1) := CHR (44);
      v_status       VARCHAR2 (20) := 'active';
      section_id     VARCHAR2 (15);
      ERR_MSG        VARCHAR2 (250);

      CURSOR get_names
      IS
         SELECT gobsrid_sourced_id user_id,
                spriden_id login_id,
                COALESCE (spbpers_pref_first_name, spriden_first_name)
                   first_name,
                spriden_last_name last_name,
                   spriden_last_name
                || ', '
                || COALESCE (spbpers_pref_first_name, spriden_first_name)
                   sortable_name,
                   COALESCE (spbpers_pref_first_name, spriden_first_name)
                || ' '
                || spriden_last_name
                   short_name,
                'active' status
           FROM spriden
                LEFT JOIN spbpers ON spbpers_pidm = spriden_pidm
                LEFT JOIN gobsrid ON gobsrid_pidm = spriden_pidm
          WHERE     spriden_pidm IN (SELECT sfrstcr_pidm
                                       FROM sfrstcr
                                      WHERE sfrstcr_term_code IN (SELECT term_code
                                                                    FROM TABLE (F_LIST_ACTIVETERMS)))
                AND spriden_change_ind IS NULL;


      names_rec      get_names%ROWTYPE;
   BEGIN
      OPEN get_names;

      LOOP
         BEGIN
            names_rec := NULL;

            FETCH get_names INTO names_rec;

            EXIT WHEN get_names%NOTFOUND;

            record_count := record_count + 1;

            file_array (record_count) :=
                  names_rec.user_id
               || v_delim
               || names_rec.login_id
               || v_delim
               || f_enclose (names_rec.first_name)
               || v_delim
               || f_enclose (names_rec.last_name)
               || v_delim
               || f_enclose (names_rec.sortable_name)
               || v_delim
               || f_enclose (names_rec.short_name)
               || v_delim
               || names_rec.status;
         END;
      END LOOP;

      p_write_file (file_header, file_array, v_file_name);

      CLOSE get_names;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ERR_MSG := 'ERR Names Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
      WHEN OTHERS
      THEN
         ERR_MSG := 'ERR Names Process - ' || SUBSTR (SQLERRM, 1, 200);
         p_error (ERR_MSG);
   END p_preferred_names;
END z_canvas_extracts;
/