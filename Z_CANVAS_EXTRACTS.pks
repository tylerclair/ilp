CREATE OR REPLACE PACKAGE BANINST1.z_canvas_extracts
AS
   TYPE record_table IS TABLE OF VARCHAR2 (500)
      INDEX BY PLS_INTEGER;

   /* TODO enter package declarations (types, exceptions, methods etc) here */

   FUNCTION f_get_email (p_pidm IN NUMBER)
      RETURN VARCHAR2;

   FUNCTION f_get_account_id (p_crn IN VARCHAR2, p_term IN VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE process_jobsub (one_up_no IN gjbprun.gjbprun_one_up_no%TYPE);

   PROCEDURE p_error (error_message IN VARCHAR2);

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
      p_run_preferred_names   IN VARCHAR2 DEFAULT 'Y');

   PROCEDURE p_write_file (file_header       IN VARCHAR2,
                           file_data_array   IN record_table,
                           file_name         IN VARCHAR2);

   PROCEDURE p_sourced_id (p_source_pidm   IN     NUMBER,
                           p_sourced_id       OUT VARCHAR2);

   PROCEDURE p_get_section_id (p_crn          IN     VARCHAR2,
                               p_term         IN     VARCHAR2,
                               p_section_id      OUT VARCHAR2);

   PROCEDURE p_get_course_id (p_crn         IN     VARCHAR2,
                              p_term        IN     VARCHAR2,
                              p_course_id      OUT VARCHAR2);

   PROCEDURE p_canvas_terms;

   PROCEDURE p_canvas_users_student (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_canvas_users_employee (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_accounts (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_course_info (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_section_info (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_enrollment (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_xlist (term_in IN VARCHAR2 DEFAULT '201140');

   PROCEDURE p_preferred_names;
END z_canvas_extracts;
/