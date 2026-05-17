CLASS ycl_aai_fc_ci_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS run_inspection
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
                i_check_variant     TYPE sci_chkv OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS run_inspection_via_job
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
                i_check_variant     TYPE sci_chkv OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_inspection_results
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_inspection_status
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _run_inspection
      IMPORTING
        i_transport_request TYPE trkorr
        i_check_variant     TYPE sci_chkv
        i_via_job           TYPE abap_bool DEFAULT abap_true
      EXPORTING
        e_rc                TYPE sysubrc
        e_error             TYPE string.

ENDCLASS.



CLASS ycl_aai_fc_ci_tools IMPLEMENTATION.

  METHOD _run_inspection.

    CONSTANTS c_error TYPE string VALUE 'Error while creating inspection run'.

    DATA: lo_obj_set    TYPE REF TO cl_ci_objectset,
          lo_chk_var    TYPE REF TO cl_ci_checkvariant,
          lo_inspection TYPE REF TO cl_ci_inspection.

    e_rc = 0.

    FREE e_error.

    cl_ci_objectset=>get_ref(
      EXPORTING
        p_korr                    = i_transport_request
        p_type                    = cl_ci_objectset=>c_0kor
        p_korr_skip_svim          = abap_true
      RECEIVING
        p_ref                     = lo_obj_set
      EXCEPTIONS
        missing_parameter         = 1
        objs_not_exists           = 2
        invalid_request           = 3
        object_not_exists         = 4
        object_may_not_be_checked = 5
        no_main_program           = 6
        OTHERS                    = 7
    ).

    IF sy-subrc <> 0.
      e_error = c_error.
      RETURN.
    ENDIF.

    cl_ci_checkvariant=>get_ref(
        EXPORTING
          p_user            = space
          p_name            = i_check_variant
        RECEIVING
          p_ref             = lo_chk_var
        EXCEPTIONS
          chkv_not_exists   = 1
          missing_parameter = 2
          OTHERS            = 3
    ).

    IF sy-subrc <> 0.
      e_error = c_error.
      RETURN.
    ENDIF.

    cl_ci_inspection=>create(
        EXPORTING
          p_name              = CONV #( i_transport_request )
          p_user              = sy-uname
        RECEIVING
          p_ref               = lo_inspection
        EXCEPTIONS
          insp_already_exists = 1
          insp_not_exists     = 2
          locked              = 3
          error_in_enqueue    = 4
          OTHERS              = 5
    ).

    IF sy-subrc <> 0.
      e_error = c_error.
      RETURN.
    ENDIF.

    lo_inspection->set(
        EXPORTING
          p_chkv       = lo_chk_var
          p_objs       = lo_obj_set
          p_noaunit    = 'X'
        EXCEPTIONS
          not_enqueued = 1
          OTHERS       = 2
    ).

    IF sy-subrc <> 0.
      e_error = c_error.
      RETURN.
    ENDIF.

    lo_inspection->save(
      EXCEPTIONS
        missing_information = 1                " Missing information
        insp_no_name        = 2                " Save inspection without name
        not_enqueued        = 3                " Inspection not yet locked
        OTHERS              = 4
    ).

    IF sy-subrc <> 0.
      e_error = c_error.
      RETURN.
    ENDIF.

    IF i_via_job = abap_true.

      lo_inspection->run_in_batch(
        EXPORTING
          p_servergroup  = 'parallel_generators'
          p_no_popup     = abap_true
        EXCEPTIONS
          error_in_batch = 1
          OTHERS         = 2
      ).

      IF sy-subrc <> 0.
        e_error = c_error.
        RETURN.
      ENDIF.

    ELSE.

      lo_inspection->run(
        EXCEPTIONS
          missing_information    = 1
          cancel_popup           = 2
          insp_already_run       = 3
          no_object              = 4
          too_many_objects       = 5
          could_not_read_variant = 6
          locked                 = 7
          objs_locked            = 8
          error_in_objs_build    = 9
          invalid_check_version  = 10
          just_running           = 11
          error_in_batch         = 12
          not_authorized         = 13
          no_server_found        = 14
          verify_error           = 15
          OTHERS                 = 16
      ).

      IF sy-subrc <> 0.
        e_error = c_error.
        RETURN.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD run_inspection.

    DATA: l_transport_request TYPE trkorr,
          l_check_variant     TYPE sci_chkv VALUE 'DEFAULT' ##NO_TEXT.

    FREE r_response.

    l_transport_request = to_upper( condense( i_transport_request ) ).

    IF i_check_variant IS NOT INITIAL.
      l_check_variant = to_upper( condense( i_check_variant ) ).
    ENDIF.

    me->_run_inspection(
      EXPORTING
        i_transport_request = l_transport_request
        i_check_variant     = l_check_variant
        i_via_job           = abap_false
      IMPORTING
        e_rc                = DATA(l_rc)
        e_error             = DATA(l_error)
    ).

    IF l_rc <> 0.
      r_response = l_error.
      RETURN.
    ENDIF.

    r_response = me->get_inspection_results(
      EXPORTING
        i_transport_request = i_transport_request
    ).

  ENDMETHOD.

  METHOD run_inspection_via_job.

    DATA: l_transport_request TYPE trkorr,
          l_check_variant     TYPE sci_chkv VALUE 'DEFAULT' ##NO_TEXT.

    FREE r_response.

    l_transport_request = to_upper( condense( i_transport_request ) ).

    IF i_check_variant IS NOT INITIAL.
      l_check_variant = to_upper( condense( i_check_variant ) ).
    ENDIF.

    me->_run_inspection(
      EXPORTING
        i_transport_request = l_transport_request
        i_check_variant     = l_check_variant
      IMPORTING
        e_rc                = DATA(l_rc)
        e_error             = DATA(l_error)
    ).

    IF l_rc <> 0.
      r_response = l_error.
      RETURN.
    ENDIF.

    r_response = 'Inspection created and put to run via job'.

  ENDMETHOD.

  METHOD get_inspection_results.

    DATA: lo_inspection TYPE REF TO cl_ci_inspection.

    DATA: l_transport_request TYPE trkorr.

    FREE r_response.

    l_transport_request = to_upper( condense( i_transport_request ) ).

    cl_ci_inspection=>get_ref(
      EXPORTING
        p_user          = sy-uname
        p_name          = CONV #( l_transport_request )
*        p_id            =
*        p_vers          =
*        p_for_deletion  = ''
      RECEIVING
        p_ref           = lo_inspection
      EXCEPTIONS
        insp_not_exists = 1
        OTHERS          = 2
    ).

    IF sy-subrc <> 0.

      r_response = |Inspection { l_transport_request } does not exist|.

    ENDIF.

    CASE lo_inspection->inspecinf-execstatus.

      WHEN 'R'.

        r_response = |Inspection { l_transport_request } current status is 'running'|.

        RETURN.

      WHEN 'O'.

        r_response = |Inspection { l_transport_request } current status is 'not done'|.

        RETURN.

      WHEN 'B'.

        r_response = |Inspection { l_transport_request } current status is 'planned'|.

        RETURN.

    ENDCASE.

    lo_inspection->plain_list(
      IMPORTING
        p_list = DATA(lt_list)
    ).

    IF lt_list IS INITIAL.
      r_response = |No results found for inspection { l_transport_request }|.
      RETURN.
    ENDIF.

    r_response = 'Object Type;Object Name;Package;Author;Message Type;'.

    LOOP AT lt_list ASSIGNING FIELD-SYMBOL(<ls_list>).

      IF <ls_list>-kind = 'N'.
        CONTINUE.
      ENDIF.

      r_response = r_response && cl_abap_char_utilities=>newline.
      r_response = r_response && <ls_list>-objtype && ';'.
      r_response = r_response && <ls_list>-objname && ';'.
      r_response = r_response && <ls_list>-devclass && ';'.
      r_response = r_response && <ls_list>-author && ';'.

      IF <ls_list>-kind = 'E'.
        r_response = r_response && 'Error;'.
      ELSEIF <ls_list>-kind = 'W'.
        r_response = r_response && 'Warning;'.
      ELSE.
        r_response = r_response && 'Unknown;'.
      ENDIF.

      r_response = r_response && <ls_list>-text && ';'.
      r_response = r_response && <ls_list>-description && ';'.

      IF <ls_list>-objtype = 'CLAS' AND <ls_list>-sobjname IS NOT INITIAL.

        cl_oo_classname_service=>get_method_by_include(
          EXPORTING
            incname             = <ls_list>-sobjname
          RECEIVING
            mtdkey              = DATA(l_method_key)
          EXCEPTIONS
            class_not_existing  = 1
            method_not_existing = 2
            OTHERS              = 3
        ).

        IF sy-subrc = 0.

          SPLIT l_method_key AT space INTO DATA(l_class) <ls_list>-sobjname.

          <ls_list>-sobjname = condense( <ls_list>-sobjname ).

        ENDIF.

      ENDIF.

      r_response = r_response && <ls_list>-sobjtype && ';'.
      r_response = r_response && <ls_list>-sobjname && ';'.
      r_response = r_response && <ls_list>-line && ';'.
      r_response = r_response && <ls_list>-col.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_inspection_status.

    DATA: lo_inspection TYPE REF TO cl_ci_inspection.

    DATA: l_transport_request TYPE trkorr.

    FREE r_response.

    l_transport_request = to_upper( condense( i_transport_request ) ).

    cl_ci_inspection=>get_ref(
      EXPORTING
        p_user          = sy-uname
        p_name          = CONV #( l_transport_request )
*        p_id            =
*        p_vers          =
*        p_for_deletion  = ''
      RECEIVING
        p_ref           = lo_inspection
      EXCEPTIONS
        insp_not_exists = 1
        OTHERS          = 2
    ).

    IF sy-subrc <> 0.

      r_response = |Inspection { l_transport_request } does not exist|.

    ENDIF.

    CASE lo_inspection->inspecinf-execstatus.

      WHEN 'X'.

        r_response = |Inspection { l_transport_request } current status is 'performed'|.

      WHEN 'R'.

        r_response = |Inspection { l_transport_request } current status is 'running'|.

      WHEN 'O'.

        r_response = |Inspection { l_transport_request } current status is 'not done'|.

      WHEN 'B'.

        r_response = |Inspection { l_transport_request } current status is 'planned'|.

    ENDCASE.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_run_inspection) = abap_false.

    DATA(l_run_inspection_via_job) = abap_false.

    DATA(l_get_inspection_status) = abap_true.

    DATA(l_get_inspection_results) = abap_false.

    CASE abap_true.

      WHEN l_run_inspection.

        l_response = me->run_inspection(
          EXPORTING
            i_transport_request = 'NPLK900129'
            i_check_variant     = 'DEFAULT'
        ).

      WHEN l_run_inspection_via_job.

        me->run_inspection_via_job(
          EXPORTING
            i_transport_request = 'NPLK900129'
            i_check_variant     = 'DEFAULT'
        ).

      WHEN l_get_inspection_status.

        l_response = me->get_inspection_status( 'NPLK900129' ).

      WHEN l_get_inspection_results.

        l_response = me->get_inspection_results( 'NPLK900129' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
