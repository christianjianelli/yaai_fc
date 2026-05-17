CLASS ycl_aai_fc_atc_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS c_error TYPE string VALUE 'Error while creating the ATC Run'.

    METHODS run
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
                i_check_variant     TYPE sci_chkv OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_results
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_atc_tools IMPLEMENTATION.

  METHOD run.

    DATA: lo_object_set         TYPE REF TO if_satc_object_set,
          lo_variant            TYPE REF TO if_satc_check_variant,
          lo_configuration      TYPE REF TO if_satc_run_configuration,
          lo_controller         TYPE REF TO if_satc_run_controller,
          lo_result_access      TYPE REF TO if_satc_result_access,
          lo_exception          TYPE REF TO cx_root,
          lt_findings           TYPE scit_rest,
          lt_findings_extension TYPE satc_ci_findings_extension,
          ls_ext_field_list     TYPE satc_ci_finding_ext_field_list,
          l_msg                 TYPE string,
          l_description(128)    TYPE c.

    DATA: l_transport_request   TYPE trkorr,
          l_check_variant       TYPE sci_chkv VALUE 'DEFAULT' ##NO_TEXT,
          l_finding_description TYPE string.


    FREE r_response.

    l_transport_request = to_upper( condense( i_transport_request ) ).

    IF i_check_variant IS NOT INITIAL.
      l_check_variant = to_upper( condense( i_check_variant ) ).
    ENDIF.

    DATA(lo_factory) = NEW cl_satc_api_factory( ).

    TRY.

        lo_object_set = cl_satc_object_set_factory=>create_for_transport( i_transport = l_transport_request ).

      CATCH cx_satc_empty_object_set
            cx_satc_not_found
            cx_satc_invalid_argument
            cx_satc_failure INTO lo_exception.

        r_response = c_error.

        RETURN.

    ENDTRY.

    TRY.

        lo_variant = lo_factory->get_repository( )->load_ci_check_variant( i_name = l_check_variant ).

      CATCH cx_satc_not_found INTO lo_exception.

        r_response = c_error.

        RETURN.

    ENDTRY.

    l_description = l_transport_request.

    lo_configuration = lo_factory->create_run_config_with_chk_var(
      i_object_set = lo_object_set
      i_check_variant = lo_variant
      i_description = l_description
    ).

    lo_configuration->set_pragma_option( i_option = if_satc_ac_project_constants=>c_mode_fndng_xmptd_in_code-do_not_show ).

    lo_controller = lo_factory->create_run_controller( lo_configuration ).

    TRY.

        lo_controller->run( IMPORTING e_result_access = lo_result_access ).

      CATCH cx_satc_failure INTO lo_exception.

        r_response = c_error.

        RETURN.

    ENDTRY.

    ls_ext_field_list-description_lines = abap_true.

    TRY.

        lo_result_access->get_findings(
          EXPORTING
            i_ext_field_list     = ls_ext_field_list
          IMPORTING
            e_findings           = lt_findings
            e_findings_extension = lt_findings_extension ).

      CATCH cx_satc_failure INTO lo_exception.

        r_response = c_error.

        RETURN.

    ENDTRY.

    IF lt_findings IS INITIAL.

      r_response = |ATC Run executed for transport request `{ l_transport_request }`. No errors or warnings found.|.

      RETURN.

    ENDIF.

    r_response = 'Object Type;Object Name;Author;Type;Description;Sub Object Type; Sub Object Name;Line;Column'.

    LOOP AT lt_findings ASSIGNING FIELD-SYMBOL(<ls_finding>).

      DATA(l_index) = sy-tabix.

      IF <ls_finding>-kind = 'N'.
        CONTINUE.
      ENDIF.

      r_response = r_response && cl_abap_char_utilities=>newline.
      r_response = r_response && <ls_finding>-objtype && ';'.
      r_response = r_response && <ls_finding>-objname && ';'.
      r_response = r_response && <ls_finding>-ciuser && ';'.

      IF <ls_finding>-kind = 'E'.
        r_response = r_response && 'Error;'.
      ELSEIF <ls_finding>-kind = 'W'.
        r_response = r_response && 'Warning;'.
      ELSE.
        r_response = r_response && 'Unknown;'.
      ENDIF.

      READ TABLE lt_findings_extension ASSIGNING FIELD-SYMBOL(<ls_findings_extension>) INDEX l_index.

      IF sy-subrc = 0.

        LOOP AT <ls_findings_extension>-description_lines ASSIGNING FIELD-SYMBOL(<ls_description_line>).

          IF l_finding_description IS INITIAL.
            l_finding_description = <ls_description_line>.
          ELSE.
            l_finding_description = |{ l_finding_description } { <ls_description_line> }|.
          ENDIF.

        ENDLOOP.

      ENDIF.

      r_response = r_response && l_finding_description && ';'.

      FREE l_finding_description.

      IF <ls_finding>-objtype = 'CLAS' AND <ls_finding>-sobjname IS NOT INITIAL.

        cl_oo_classname_service=>get_method_by_include(
          EXPORTING
            incname             = <ls_finding>-sobjname
          RECEIVING
            mtdkey              = DATA(l_method_key)
          EXCEPTIONS
            class_not_existing  = 1
            method_not_existing = 2
            OTHERS              = 3
        ).

        IF sy-subrc = 0.

          SPLIT l_method_key AT space INTO DATA(l_class) <ls_finding>-sobjname.

          <ls_finding>-sobjname = condense( <ls_finding>-sobjname ).

          <ls_finding>-sobjtype = 'METHOD'.

          CLEAR l_method_key.

        ENDIF.

      ENDIF.

      r_response = r_response && <ls_finding>-sobjtype && ';'.
      r_response = r_response && <ls_finding>-sobjname && ';'.
      r_response = r_response && <ls_finding>-line && ';'.
      r_response = r_response && <ls_finding>-col.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_results.

    DATA lo_test TYPE REF TO cl_ci_test_root.

    DATA lt_findings TYPE scit_rest.

    DATA lt_findings_ext TYPE satc_ci_findings_extension.

    DATA l_transport_request TYPE trkorr.

    DATA l_finding_description TYPE string.

    l_transport_request = to_upper( condense( i_transport_request ) ).

    DATA(lo_factory) = NEW cl_satc_api_factory( ).

    SELECT display_id, title, scheduled_by, scheduled_on_ts
      FROM satc_ac_resulth
     WHERE scheduled_by = @sy-uname
       AND title = @l_transport_request
      ORDER BY scheduled_on_ts
      INTO TABLE @DATA(lt_atc_ac_result).

    IF sy-subrc <> 0.

      RETURN.
    ENDIF.

    DATA(l_result_id) = lt_atc_ac_result[ lines( lt_atc_ac_result ) ]-display_id.

    CALL FUNCTION 'SATC_CI_GET_RESULT'
      EXPORTING
        i_result_id         = l_result_id
*       i_name_range_pairs  =
*       i_statistics_only   = ''
*       i_ext_field_list    =
      IMPORTING
        e_results           = lt_findings
        e_results_extension = lt_findings_ext
*       e_read_errors       =
*       e_total_findings    =
*       e_ext_field_list    =
*       e_has_more          =
      EXCEPTIONS
        not_authorized      = 1
        invalid_result_id   = 2
        OTHERS              = 3.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    r_response = 'Object Type;Object Name;Author;Type;Description;Sub Object Type; Sub Object Name;Line;Column'.

    LOOP AT lt_findings ASSIGNING FIELD-SYMBOL(<ls_finding>).

      DATA(l_index) = sy-tabix.

      IF <ls_finding>-kind = 'N'.
        CONTINUE.
      ENDIF.

      r_response = r_response && cl_abap_char_utilities=>newline.
      r_response = r_response && <ls_finding>-objtype && ';'.
      r_response = r_response && <ls_finding>-objname && ';'.
      r_response = r_response && <ls_finding>-ciuser && ';'.

      IF <ls_finding>-kind = 'E'.
        r_response = r_response && 'Error;'.
      ELSEIF <ls_finding>-kind = 'W'.
        r_response = r_response && 'Warning;'.
      ELSE.
        r_response = r_response && 'Unknown;'.
      ENDIF.

      READ TABLE lt_findings_ext ASSIGNING FIELD-SYMBOL(<ls_findings_ext>) INDEX l_index.

      IF sy-subrc = 0.

        LOOP AT <ls_findings_ext>-description_lines ASSIGNING FIELD-SYMBOL(<ls_description_line>).

          IF l_finding_description IS INITIAL.
            l_finding_description = <ls_description_line>.
          ELSE.
            l_finding_description = |{ l_finding_description } { <ls_description_line> }|.
          ENDIF.

        ENDLOOP.

      ENDIF.

      r_response = r_response && l_finding_description && ';'.

      FREE l_finding_description.

      IF <ls_finding>-objtype = 'CLAS' AND <ls_finding>-sobjname IS NOT INITIAL.

        cl_oo_classname_service=>get_method_by_include(
          EXPORTING
            incname             = <ls_finding>-sobjname
          RECEIVING
            mtdkey              = DATA(l_method_key)
          EXCEPTIONS
            class_not_existing  = 1
            method_not_existing = 2
            OTHERS              = 3
        ).

        IF sy-subrc = 0.

          SPLIT l_method_key AT space INTO DATA(l_class) <ls_finding>-sobjname.

          <ls_finding>-sobjname = condense( <ls_finding>-sobjname ).

          <ls_finding>-sobjtype = 'METHOD'.

          CLEAR l_method_key.

        ENDIF.

      ENDIF.

      r_response = r_response && <ls_finding>-sobjtype && ';'.
      r_response = r_response && <ls_finding>-sobjname && ';'.
      r_response = r_response && <ls_finding>-line && ';'.
      r_response = r_response && <ls_finding>-col.

    ENDLOOP.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_run) = abap_true.
    DATA(l_get_results) = abap_false.

    CASE abap_true.

      WHEN l_run.

        l_response = me->run(
          EXPORTING
            i_transport_request = 'NPLK900129'
            i_check_variant     = 'DEFAULT'
        ).

      WHEN l_get_results.

        l_response = me->get_results(
          EXPORTING
            i_transport_request = 'NPLK900129'
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
