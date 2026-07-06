CLASS ycl_aai_fc_oo_interface_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'INTF',
               mc_uri    TYPE string      VALUE '/sap/bc/adt/oo/interfaces'.

    METHODS create
      IMPORTING
                i_interface_name    TYPE yde_aai_fc_oo_interface_name
                i_short_description TYPE as4text
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_interface_name  TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_interface_name    TYPE yde_aai_fc_oo_interface_name OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_properties
      IMPORTING
                i_interface_name  TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_response) TYPE string.

    METHODS update
      IMPORTING
                i_interface_name    TYPE yde_aai_fc_oo_interface_name
                i_short_description TYPE as4text OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_source            TYPE string
      RETURNING VALUE(r_response)   TYPE string.

    METHODS check_syntax
      IMPORTING
                i_interface_name  TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_response) TYPE string.

    METHODS activate
      IMPORTING
                i_interface_name  TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_response) TYPE string.

    METHODS get_current_transport_request
      IMPORTING
                i_interface_name  TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _t_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

    DATA _lock_handle TYPE string.

    METHODS _get_source_code
      IMPORTING
                i_interface_name TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_source)  TYPE string.

    METHODS _lock
      IMPORTING
        i_interface_name TYPE yde_aai_fc_oo_interface_name.

    METHODS _unlock
      IMPORTING
        i_interface_name TYPE yde_aai_fc_oo_interface_name.

    METHODS _get_properties
      IMPORTING
        i_interface_name TYPE yde_aai_fc_oo_interface_name
      EXPORTING
        e_error_message  TYPE string
        e_s_intf_data    TYPE if_adt_oo_types=>ty_intf_data.

    METHODS _set_properties
      IMPORTING
        i_interface_name    TYPE yde_aai_fc_oo_interface_name
        i_s_intf_data       TYPE if_adt_oo_types=>ty_intf_data
        i_transport_request TYPE yde_aai_fc_transport_request
      EXPORTING
        e_success           TYPE abap_bool
        e_error_description TYPE string.

    METHODS _get_line_and_column_from_uri
      IMPORTING
        i_uri    TYPE csequence
      EXPORTING
        e_line   TYPE i
        e_column TYPE i.

    METHODS _deserialize_check_run_reports
      IMPORTING
        i_xml                TYPE xstring
      EXPORTING
        et_check_run_reports TYPE if_adt_check_run_response=>gty_check_run_reports.

    METHODS _is_active
      IMPORTING
                i_interface_name   TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_is_active) TYPE abap_bool.

ENDCLASS.



CLASS ycl_aai_fc_oo_interface_tools IMPLEMENTATION.

  METHOD create.

    DATA: ls_request   TYPE sadt_rest_request,
          ls_response  TYPE sadt_rest_response,
          ls_intf_data TYPE if_adt_oo_types=>ty_intf_data,
          ls_exc_data  TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ mc_uri }?corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    ls_intf_data-description = i_short_description.
    ls_intf_data-language = sy-langu.
    ls_intf_data-name = to_upper( condense( i_interface_name ) ).
    ls_intf_data-type = 'INTF/OI' ##NO_TEXT.
    ls_intf_data-responsible = sy-uname.
    ls_intf_data-master_system = sy-sysid.
    ls_intf_data-master_language = sy-langu.
    ls_intf_data-package_ref-name = to_upper( condense( i_package ) ).

    TRY.

        CALL TRANSFORMATION intf_transformation
          SOURCE
            intf_data = ls_intf_data
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.

        r_response = |An error occured while creating the interface { i_interface_name }.|.

        RETURN.
    ENDTRY.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS NOT INITIAL.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF ls_exc_data-message IS NOT INITIAL.

      r_response = ls_exc_data-message.

      RETURN.

    ENDIF.

    r_response = |Interface { i_interface_name } created successfully!|.

  ENDMETHOD.

  METHOD read.

    DATA(l_interface_name) = i_interface_name.

    l_interface_name =  to_upper( condense( l_interface_name ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_interface_name
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Interface { l_interface_name } not found.|.
      RETURN.
    ENDIF.

    r_response = me->_get_source_code( i_interface_name ).

*    DATA: lo_result_obj_intf     TYPE REF TO if_oo_clif_source,
*          lo_object_source_class TYPE REF TO cl_oo_clif_source.
*
*    DATA: l_version TYPE if_adt_tools_core_types=>ty_object-version,
*          l_source  TYPE string.
*
*
*    l_version = if_adt_uri_query_parameters=>co_version_active.
*
*    lo_result_obj_intf = cl_oo_factory=>create_instance( )->create_clif_source(
*        clif_name = i_interface_name
*        version   = cl_adt_utility=>get_wb_version( l_version )
*    ).
*
*    TRY.
*        lo_object_source_class ?= lo_result_obj_intf.
*        lo_object_source_class->access_permission( access_mode = seok_access_show ).
*      CATCH cx_oo_access_permission INTO DATA(lo_obj_err).
*        IF lo_obj_err IS BOUND.
*          RETURN.
*        ENDIF.
*      CATCH cx_sy_move_cast_error ##no_handler.
*    ENDTRY.
*
*    lo_object_source_class->get_source(
*      IMPORTING
*        source = DATA(lt_source)
*    ).
*
*    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<l_line>).
*
*      IF l_source IS INITIAL.
*        l_source = <l_line> && cl_abap_char_utilities=>newline.
*      ELSE.
*        l_source = l_source  && <l_line> && cl_abap_char_utilities=>newline.
*      ENDIF.
*
*    ENDLOOP.
*
*    r_response = l_source.

  ENDMETHOD.

  METHOD search.

    DATA: l_interface_name    TYPE string,
          l_short_description TYPE string.

    CLEAR r_response.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    SELECT pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND devclass = @l_package
        AND delflag <> @abap_true
      INTO TABLE @DATA(lt_tadir).                       "#EC CI_GENBUFF

    IF sy-subrc <> 0.
      r_response = |No interface found in package { l_package }.|.
      RETURN.
    ENDIF.

    l_interface_name = |*{ i_interface_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_interface_name IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_interface_name.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      SELECT clsname, version
        FROM seoclassdf
        WHERE clsname = @<ls_tadir>-obj_name
        INTO TABLE @DATA(lt_seoclassdf).

      READ TABLE lt_seoclassdf TRANSPORTING NO FIELDS
        WITH KEY version = '0'.

      IF sy-subrc = 0.
        DATA(l_inactive) = abap_true.
      ENDIF.

      SELECT SINGLE clsname, langu, descript
        FROM seoclasstx
        WHERE clsname = @<ls_tadir>-obj_name
          AND langu = @sy-langu
        INTO @DATA(ls_seoclasstx).

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_seoclasstx-descript CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      r_response = |{ r_response }Interface: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_seoclasstx-descript }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Package: { <ls_tadir>-devclass }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Original language: { <ls_tadir>-masterlang }{ cl_abap_char_utilities=>newline }|.

      IF l_inactive = abap_true.
        r_response = |{ r_response }Activation status: Inactive{ cl_abap_char_utilities=>newline }|.
      ELSE.
        r_response = |{ r_response }Activation status: Active{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      FREE lt_seoclassdf.

      CLEAR ls_seoclasstx.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_properties.

    CLEAR r_response.

    DATA(l_interface_name) = i_interface_name.

    l_interface_name =  to_upper( condense( l_interface_name ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_interface_name
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Interface { l_interface_name } not found.|.
      RETURN.
    ENDIF.

    SELECT clsname, version
      FROM seoclassdf
      WHERE clsname = @ls_tadir-obj_name
      INTO TABLE @DATA(lt_seoclassdf).

    READ TABLE lt_seoclassdf TRANSPORTING NO FIELDS
      WITH KEY version = '0'.

    IF sy-subrc = 0.
      DATA(l_inactive) = abap_true.
    ENDIF.

    SELECT SINGLE clsname, langu, descript
      FROM seoclasstx
      INTO @DATA(ls_seoclasstx)
      WHERE clsname = @ls_tadir-obj_name
        AND langu = @sy-langu.

    r_response = |{ r_response }Interface: { ls_tadir-obj_name }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Description: { ls_seoclasstx-descript }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Package: { ls_tadir-devclass }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Original language: { ls_tadir-masterlang }{ cl_abap_char_utilities=>newline }|.

    IF l_inactive = abap_true.
      r_response = |{ r_response }Activation status: Inactive|.
    ELSE.
      r_response = |{ r_response }Activation status: Active|.
    ENDIF.

    DATA(l_current_transport_request) = me->get_current_transport_request( l_interface_name ).

    IF l_current_transport_request IS NOT INITIAL.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Transport Request: { l_current_transport_request }|.
    ENDIF.

  ENDMETHOD.

  METHOD update.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    DATA(l_interface_name) = i_interface_name.

    l_interface_name = to_upper( condense( l_interface_name ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_interface_name
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Interface { l_interface_name } not found.|.
      RETURN.
    ENDIF.

    me->_lock( l_interface_name ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ mc_uri }/{ to_lower( l_interface_name ) }/source/main?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain' ) ).

    ls_request-message_body = cl_abap_codepage=>convert_to( source = i_source ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS NOT INITIAL.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF ls_exc_data-message IS NOT INITIAL.

      me->_unlock( l_interface_name ).

      r_response = ls_exc_data-message.

      RETURN.

    ENDIF.

    IF i_short_description IS NOT INITIAL.

      me->_get_properties(
        EXPORTING
          i_interface_name = i_interface_name
        IMPORTING
          e_s_intf_data = DATA(ls_intf_data)
      ).

      ls_intf_data-description = i_short_description.

      me->_set_properties(
        EXPORTING
          i_interface_name    = i_interface_name
          i_transport_request = i_transport_request
          i_s_intf_data       = ls_intf_data
        IMPORTING
          e_error_description = DATA(l_error_description)
          e_success           = DATA(l_properties_updated)
      ).

      IF l_properties_updated = abap_false.

        r_response = |Interface { i_interface_name } source code updated but the description was not.|.

        IF l_error_description IS NOT INITIAL.
          r_response = |{ r_response }Error: { l_error_description }|.
        ENDIF.

        me->_unlock( l_interface_name ).

        RETURN.

      ENDIF.

    ENDIF.

    me->_unlock( l_interface_name ).

    r_response = |Interface { i_interface_name } updated successfully!|.

  ENDMETHOD.

  METHOD check_syntax.

    DATA lt_checkrun_objects TYPE seu_adt_check_run_objects.

    DATA ls_request  TYPE sadt_rest_request.
    DATA ls_response TYPE sadt_rest_response.

    FREE r_response.

    FREE me->_t_check_run_reports.

    ls_request-request_line-method = 'POST'.
    ls_request-request_line-uri = '/sap/bc/adt/checkruns?reporters=abapCheckRun'.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )
                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.checkobjects+xml' )   ).

    DATA(l_interface_name) = i_interface_name.

    l_interface_name = to_lower( condense( l_interface_name ) ).

    lt_checkrun_objects = VALUE #( ( object_reference-uri = |{ me->mc_uri }/{ l_interface_name }|
                                     version = 'inactive' ) ).

    TRY.

        CALL TRANSFORMATION sadt_check_run_objects
          SOURCE
            checkrunobjects = lt_checkrun_objects
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    DATA(l_message_body) = cl_abap_codepage=>convert_from( source = ls_response-message_body ).

    me->_deserialize_check_run_reports(
      EXPORTING
        i_xml                = ls_response-message_body
      IMPORTING
        et_check_run_reports = me->_t_check_run_reports
    ).

    LOOP AT me->_t_check_run_reports ASSIGNING FIELD-SYMBOL(<ls_check_run_report>).

      LOOP AT <ls_check_run_report>-results ASSIGNING FIELD-SYMBOL(<ls_result>).

        SPLIT <ls_result>-uri AT '#start=' INTO TABLE DATA(lt_parts).

        IF lines( lt_parts ) = 2.

          SPLIT lt_parts[ 2 ] AT ',' INTO DATA(l_line) DATA(l_column).

        ENDIF.

        r_response = |{ r_response }{ <ls_result>-shorttext }{ cl_abap_char_utilities=>newline }|.

        IF l_line IS NOT INITIAL.

          r_response = |{ r_response }Line: { l_line }{ cl_abap_char_utilities=>newline }|.

          IF l_column IS NOT INITIAL.
            r_response = |{ r_response }Column: { l_column }{ cl_abap_char_utilities=>newline }|.
          ENDIF.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |The interface { i_interface_name } has no syntax errors.|.
    ENDIF.

  ENDMETHOD.

  METHOD activate.

    DATA: lt_objects   TYPE STANDARD TABLE OF dwinactiv,
          ls_object    TYPE dwinactiv,
          lv_no_force  TYPE boole_d,
          lo_checklist TYPE REF TO cl_wb_checklist.

    DATA(l_interface_name) = i_interface_name.

    l_interface_name = to_upper( condense( l_interface_name ) ).

    DATA(l_has_errors) = abap_false.

    r_response = me->check_syntax( i_interface_name = l_interface_name ).

    LOOP AT me->_t_check_run_reports ASSIGNING FIELD-SYMBOL(<ls_check_run_report>).
      IF <ls_check_run_report>-results IS NOT INITIAL.
        l_has_errors = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF l_has_errors = abap_true.
      DATA(l_response) = |Error(s) found while activating the interface { i_interface_name }.{ cl_abap_char_utilities=>newline }|.
      r_response = l_response && r_response.
      RETURN.
    ENDIF.

    ls_object-object   = me->mc_object.
    ls_object-obj_name = l_interface_name.

    APPEND ls_object TO lt_objects.

    CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
      EXPORTING
        suppress_enqueue       = abap_true
        suppress_corr_insert   = abap_true
        ui_decoupled           = abap_true
      IMPORTING
        p_no_force_activation  = lv_no_force
        p_checklist            = lo_checklist
      TABLES
        objects                = lt_objects
      EXCEPTIONS
        excecution_error       = 1
        cancelled              = 2
        insert_into_corr_error = 3
        OTHERS                 = 4.

    IF sy-subrc <> 0.
      " Handle activation error
      r_response = |Error while activating the interface { i_interface_name }.|.
      RETURN.
    ENDIF.

    lo_checklist->get_error_messages(
      IMPORTING
        p_error_tab = DATA(lt_errors)                 " Error Message Table
    ).

    LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<ls_error>).

      IF sy-tabix = 1.
        r_response = |Error(s) while activating the interface { i_interface_name }.{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      MESSAGE ID <ls_error>-message-msgid
        TYPE <ls_error>-message-msgty
        NUMBER <ls_error>-message-msgno
        WITH <ls_error>-message-msgv1
             <ls_error>-message-msgv2
             <ls_error>-message-msgv3
             <ls_error>-message-msgv4
        INTO DATA(l_message).

      r_response = |{ r_response }{ l_message }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

    IF me->_is_active( l_interface_name ) = abap_true.

      r_response = |Interface { i_interface_name } activated.|.

    ENDIF.

  ENDMETHOD.

  METHOD get_current_transport_request.

    DATA(l_interface_name) = i_interface_name.

    l_interface_name = to_upper( condense( l_interface_name ) ).

    NEW ycl_aai_fc_cts_api( )->get_current_transport_request(
      EXPORTING
        i_object_name       = l_interface_name
        i_pgmid             = mc_pgmid
        i_object            = mc_object
      IMPORTING
        e_transport_request = DATA(l_transport_request)
    ).

    r_response = l_transport_request.

  ENDMETHOD.

  METHOD _get_source_code.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA(l_interface_name) = to_lower( condense( i_interface_name ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_interface_name }/source/main|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    r_source = cl_abap_codepage=>convert_from( source = ls_response-message_body ).

  ENDMETHOD.

  METHOD _lock.

    DATA: ls_request     TYPE sadt_rest_request,
          ls_response    TYPE sadt_rest_response,
          ls_lock_result TYPE sadt_object_lock_result2.

    DATA(l_interface_name) = to_lower( condense( i_interface_name ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    "/sap/bc/adt/oo/interfaces/zif_test_create_fc_03?_action=LOCK&accessMode=MODIFY
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_interface_name }?_action=LOCK&accessMode=MODIFY|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.as+xml;charset=UTF-8;dataname=com.sap.adt.lock.result2;q=0.9' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    TRY.

        CALL TRANSFORMATION sadt_id
          SOURCE XML ls_response-message_body
          RESULT data = ls_lock_result.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

    me->_lock_handle = ls_lock_result-lock_handle.

  ENDMETHOD.

  METHOD _unlock.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA(l_interface_name) = to_lower( condense( i_interface_name ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_interface_name }?_action=UNLOCK&lockHandle={ me->_lock_handle }| ##NO_TEXT.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

  ENDMETHOD.

  METHOD _deserialize_check_run_reports.

    TRY.

        CALL TRANSFORMATION st_adt_check_run_reports
          SOURCE XML i_xml
          RESULT checkrunreports = et_check_run_reports.

      CATCH cx_transformation_error.
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD _get_line_and_column_from_uri.

    DATA: l_line   TYPE string,
          l_column TYPE string.

    e_line = 0.
    e_column = 0.

    SPLIT i_uri AT '#start=' INTO TABLE DATA(lt_parts).

    IF lines( lt_parts ) = 2.

      SPLIT lt_parts[ 2 ] AT ',' INTO l_line l_column.

      l_line = condense( l_line ).

      l_column = condense( l_column ).

      IF l_line CO '0123456789'.
        e_line = l_line.
      ENDIF.

      IF l_column CO '0123456789'.
        e_column = l_column.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD _get_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR: e_s_intf_data, e_error_message.

    DATA(l_interface_name) = to_lower( condense( i_interface_name ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_interface_name }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.oo.interfaces.v2+xml' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.
      RETURN.
    ENDIF.

    TRY.

        CALL TRANSFORMATION intf_transformation
          SOURCE XML ls_response-message_body
          RESULT intf_data = e_s_intf_data.

        RETURN.

      CATCH cx_transformation_error ##NO_HANDLER.
    ENDTRY.

    IF ls_response-message_body IS NOT INITIAL.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

    IF ls_exc_data-message IS NOT INITIAL.
      e_error_message = ls_exc_data-message.
    ENDIF.

  ENDMETHOD.

  METHOD _set_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR: e_error_description,
           e_success.

    DATA(l_interface_name) = to_lower( condense( i_interface_name ) ).
    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_interface_name }?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )

                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.oo.interfaces.v2+xml' ) ).

    TRY.

        CALL TRANSFORMATION intf_transformation
          SOURCE intf_data = i_s_intf_data
          RESULT XML ls_request-message_body.

      CATCH cx_transformation_error ##NO_HANDLER.
    ENDTRY.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.

      e_success = abap_true.

      RETURN.

    ELSE.

      e_success = abap_false.

      TRY.

          SELECT SINGLE laiso FROM t002 INTO @l_langu WHERE spras = @sy-langu.

          CALL TRANSFORMATION sadt_exception
            SOURCE XML ls_response-message_body
            RESULT exception_data = ls_exc_data
                   langu          = l_langu.

          e_error_description = ls_exc_data-message.

        CATCH cx_transformation_error ##NO_HANDLER.
      ENDTRY.

    ENDIF.

  ENDMETHOD.

  METHOD _is_active.

    DATA: lt_messages TYPE STANDARD TABLE OF sprot_u WITH DEFAULT KEY,
          lt_e071     TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.

    DATA ls_e071 TYPE e071.

    ls_e071-object   = 'INTF'.
    ls_e071-obj_name = to_upper( condense( i_interface_name ) ).
    INSERT ls_e071 INTO TABLE lt_e071.

    CALL FUNCTION 'RS_INACTIVE_OBJECTS_WARNING'
      EXPORTING
        suppress_protocol         = abap_false
        with_program_includes     = abap_false
        suppress_dictionary_check = abap_false
      TABLES
        p_e071                    = lt_e071
        p_xmsg                    = lt_messages.

    r_is_active = boolc( lt_messages IS INITIAL ).

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.
    DATA l_source   TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_get_properties) = abap_false.
    DATA(l_update) = abap_true.
    DATA(l_check) = abap_false.
    DATA(l_activate) = abap_false.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_interface_name = 'ZIF_TEST_CREATE_FC_03'
        ).

      WHEN l_search.

        l_response = me->search(
          EXPORTING
            i_package = 'Z001'
        ).

      WHEN l_get_properties.

*        l_response = me->get_properties(
*          EXPORTING
*            i_interface_name = 'ZIF_TEST_CREATE_FC_03'
*        ).

        me->_get_properties(
          EXPORTING
            i_interface_name = 'ZIF_TEST_CREATE_FC_03'
*          IMPORTING
*            e_error_message  =
*            e_s_intf_data    =
        ).

      WHEN l_create.

        l_response = me->create( i_interface_name    = 'ZIF_TEST_CREATE_FC_03'
                                 i_short_description = 'Test create tool'
                                 i_transport_request = 'NPLK900133'
                                 i_package           = 'Z001'
                               ).

      WHEN l_check.

        l_response = me->check_syntax(
          EXPORTING
            i_interface_name = 'ZIF_TEST_CREATE_FC_03' ).

      WHEN l_activate.

        l_response = me->activate(
          EXPORTING
            i_interface_name = 'ZIF_TEST_CREATE_FC_03' ).

      WHEN l_update.

        l_source = |INTERFACE ZIF_TEST_CREATE_FC_03{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source } PUBLIC .{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }   METHODS test_m1{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }     IMPORTING{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }       i_val1 TYPE csequence{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }       i_val2 TYPE csequence.{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source } ENDINTERFACE.{ cl_abap_char_utilities=>newline }|.

        l_response = me->update( i_interface_name    = 'ZIF_TEST_CREATE_FC_03'
                                 i_short_description = 'Test ADT API upd'
                                 i_transport_request = 'NPLK900142'
                                 i_source            = l_source
                               ).


    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
