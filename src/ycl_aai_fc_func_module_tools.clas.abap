CLASS ycl_aai_fc_func_module_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'FUGR',
               mc_uri    TYPE string      VALUE '/sap/bc/adt/functions/groups/&1/fmodules'.

    TYPES ty_string_t TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS read
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_function_module   TYPE rs38l_fnam OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS create
      IMPORTING
                i_function_module   TYPE rs38l_fnam
                i_short_description TYPE as4text
                i_function_group    TYPE rs38l_area
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_function_module   TYPE rs38l_fnam
                i_short_description TYPE as4text OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_source            TYPE string
      RETURNING VALUE(r_response)   TYPE string.


  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _lock_handle TYPE string.

    METHODS _is_authorized
      IMPORTING
                i_function_module   TYPE rs38l_fnam
      RETURNING VALUE(r_authorized) TYPE abap_bool.

    METHODS _get_source_code
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_source)   TYPE string.

    METHODS _get_properties
      IMPORTING
        i_function_module TYPE rs38l_fnam
      EXPORTING
        e_error_message   TYPE string
        e_s_func_data     TYPE cl_fb_adt_res_func_base=>func_data_xml.

    METHODS _get_function_group
      IMPORTING
                i_function_module       TYPE rs38l_fnam
      RETURNING VALUE(r_function_group) TYPE rs38l_area.

    METHODS _lock
      IMPORTING
        i_function_module TYPE rs38l_fnam.

    METHODS _unlock
      IMPORTING
        i_function_module TYPE rs38l_fnam.

ENDCLASS.



CLASS ycl_aai_fc_func_module_tools IMPLEMENTATION.

  METHOD read.

    TYPES: BEGIN OF ty_function,
             funcname          TYPE rs38l_fnam,
             global_flag       TYPE rs38l-global,
             remote_call       TYPE rs38l-remote,
             update_task       TYPE rs38l-utask,
             short_text        TYPE tftit-stext,
             rfcscope          TYPE c LENGTH 1,
             rfcvers           TYPE c LENGTH 10,
             import            TYPE STANDARD TABLE OF rsimp WITH DEFAULT KEY,
             changing          TYPE STANDARD TABLE OF rscha WITH DEFAULT KEY,
             export            TYPE STANDARD TABLE OF rsexp WITH DEFAULT KEY,
             tables            TYPE STANDARD TABLE OF rstbl WITH DEFAULT KEY,
             exception         TYPE STANDARD TABLE OF rsexc WITH DEFAULT KEY,
             documentation     TYPE STANDARD TABLE OF rsfdo WITH DEFAULT KEY,
             exception_classes TYPE abap_bool,
           END OF ty_function.

    DATA: lt_source     TYPE TABLE OF rssource,
          lt_new_source TYPE rsfb_source.

    DATA ls_function TYPE ty_function.

    DATA l_source TYPE string.

    DATA(l_function_module) = i_function_module.

    l_function_module = condense( to_upper( i_function_module ) ).

    IF me->_is_authorized( i_function_module ) = abap_false.
      r_response = |No authorization to read the function module { i_function_module } source code.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'RPY_FUNCTIONMODULE_READ_NEW'
      EXPORTING
        functionname       = l_function_module
      IMPORTING
        global_flag        = ls_function-global_flag
        remote_call        = ls_function-remote_call
        update_task        = ls_function-update_task
        short_text         = ls_function-short_text
      TABLES
        import_parameter   = ls_function-import
        changing_parameter = ls_function-changing
        export_parameter   = ls_function-export
        tables_parameter   = ls_function-tables
        exception_list     = ls_function-exception
        documentation      = ls_function-documentation
        source             = lt_source
      CHANGING
        new_source         = lt_new_source
      EXCEPTIONS
        error_message      = 1
        function_not_found = 2
        invalid_name       = 3
        OTHERS             = 4.

    IF sy-subrc <> 0.
      r_response = |Function module { i_function_module } not found.|.
      RETURN.
    ENDIF.


    IF lt_new_source[] IS NOT INITIAL.

      LOOP AT lt_new_source ASSIGNING FIELD-SYMBOL(<l_new_source>).

        IF l_source IS INITIAL.
          l_source = <l_new_source> && cl_abap_char_utilities=>newline.
        ELSE.
          l_source = l_source  && <l_new_source> && cl_abap_char_utilities=>newline.
        ENDIF.

      ENDLOOP.

    ELSE.

      LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<ls_source>).

        IF l_source IS INITIAL.
          l_source = <ls_source>-line && cl_abap_char_utilities=>newline.
        ELSE.
          l_source = l_source  && <ls_source>-line && cl_abap_char_utilities=>newline.
        ENDIF.

      ENDLOOP.

    ENDIF.

    r_response = | - **Function Module**: { l_function_module }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    IF ls_function-remote_call IS INITIAL AND ls_function-update_task IS INITIAL.

      r_response = |{ r_response } - **Type**: Regular Function Module{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ELSEIF ls_function-remote_call IS NOT INITIAL.

      r_response = |{ r_response } - **Type**: Remote-Enabled Module (RFC){ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ELSEIF ls_function-update_task IS NOT INITIAL.

      r_response = |{ r_response } - **Type**: Update Module{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ENDIF.

    r_response = |{ r_response } - **Short text**: { ls_function-short_text }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }```abap|.

    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ l_source }```|.

  ENDMETHOD.

  METHOD search.

    DATA: l_function_module   TYPE string,
          l_short_description TYPE string.

    CLEAR r_response.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    SELECT pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND devclass = @l_package
      INTO TABLE @DATA(lt_tadir).                       "#EC CI_GENBUFF

    IF sy-subrc <> 0.
      r_response = |No function module found in package { l_package }.|.
      RETURN.
    ENDIF.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).
      <ls_tadir>-obj_name = 'SAPL' && <ls_tadir>-obj_name.
    ENDLOOP.

    SELECT funcname, pname
      FROM tfdir
      FOR ALL ENTRIES IN @lt_tadir
      WHERE pname = @lt_tadir-obj_name
      INTO TABLE @DATA(lt_tfdir).                       "#EC CI_GENBUFF

    SORT lt_tfdir BY pname.

    IF lt_tfdir IS NOT INITIAL.

      SELECT spras, funcname, stext
        FROM tftit
        FOR ALL ENTRIES IN @lt_tfdir
        WHERE spras = @sy-langu
          AND funcname = @lt_tfdir-funcname
        ORDER BY PRIMARY KEY
        INTO TABLE @DATA(lt_tftit).

    ENDIF.

    l_function_module = |*{ i_function_module }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING <ls_tadir>.

      READ TABLE lt_tfdir TRANSPORTING NO FIELDS
        WITH KEY pname = <ls_tadir>-obj_name
        BINARY SEARCH.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(l_tabix) = sy-tabix.

      LOOP AT lt_tfdir ASSIGNING FIELD-SYMBOL(<ls_tfdir>) FROM l_tabix.

        IF <ls_tfdir>-pname <> <ls_tadir>-obj_name.
          EXIT.
        ENDIF.

        IF r_response IS NOT INITIAL.
          r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
        ENDIF.

        r_response = |{ r_response }Function Module: { <ls_tfdir>-funcname }{ cl_abap_char_utilities=>newline }|.

        READ TABLE lt_tftit ASSIGNING FIELD-SYMBOL(<ls_tftit>)
          WITH KEY spras = sy-langu
                   funcname =  <ls_tfdir>-funcname
          BINARY SEARCH.

        IF sy-subrc = 0.
          r_response = |{ r_response }Description: { <ls_tftit>-stext }{ cl_abap_char_utilities=>newline }|.
        ELSE.

          SELECT spras, funcname, stext
            FROM tftit
            WHERE funcname = @<ls_tfdir>-funcname
            INTO @DATA(ls_tftit)
            UP TO 1 ROWS.                               "#EC CI_GENBUFF
          ENDSELECT.

          r_response = |{ r_response }Description: { ls_tftit-stext }{ cl_abap_char_utilities=>newline }|.

        ENDIF.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD create.

    DATA: ls_request   TYPE sadt_rest_request,
          ls_response  TYPE sadt_rest_response,
          ls_func_data TYPE cl_fb_adt_res_func_base=>func_data_xml,
          ls_exc_data  TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_function_group) = to_lower( condense( i_function_group ) ).

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ mc_uri }?corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )
                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.functions.fmodules.v2+xml' ) ).

    ls_func_data-description = i_short_description.
    ls_func_data-language = sy-langu.
    ls_func_data-name = to_upper( condense( i_function_module ) ).
    ls_func_data-type = 'FUGR/FF' ##NO_TEXT.
*    ls_func_data-responsible = sy-uname.
*    ls_func_data-master_system = sy-sysid.
*    ls_func_data-master_language = sy-langu.
*    ls_func_data-package_ref-name = to_upper( condense( i_package ) ).

    TRY.

        CALL TRANSFORMATION st_fb_adt_func
          SOURCE
            func_data = ls_func_data
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.

        r_response = |An error occured while creating the function module { i_function_module }.|.

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

    r_response = |Function Module { i_function_module } created successfully!|.

  ENDMETHOD.

  METHOD update.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_function_module) = to_upper( condense( i_function_module ) ).

    SELECT SINGLE @abap_true
      FROM tfdir
      WHERE funcname = @l_function_module
      INTO @DATA(l_exists).

    IF sy-subrc <> 0.
      r_response = |Function Module { i_function_module } not found.|.
      RETURN.
    ENDIF.

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    me->_lock( i_function_module ).

    ls_request-request_line-method = 'PUT'.
    ls_request-request_line-uri = |{ mc_uri }/{ to_lower( l_function_module ) }/source/main?lockHandle={ me->_lock_handle }&corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain, application/vnd.sap.adt.checkmessages+xml' )

                                         ( name = 'Content-Type'
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

      me->_unlock( i_function_module ).

      r_response = ls_exc_data-message.

      RETURN.

    ENDIF.

    me->_unlock( i_function_module ).

    r_response = |Function Module { i_function_module } updated successfully!|.

  ENDMETHOD.

  METHOD _is_authorized.

    "TODO

    r_authorized = abap_true.

  ENDMETHOD.

  METHOD _get_source_code.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA l_function_group_name TYPE string.

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    l_function_group_name = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }/source/main|.
    ls_request-request_line-version = 'HTTP/1.1'.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'text/plain' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    r_source = cl_abap_codepage=>convert_from( source = ls_response-message_body ).

  ENDMETHOD.

  METHOD _get_function_group.

    CLEAR r_function_group.

    DATA(l_function_module) = to_upper( condense( i_function_module ) ).

    SELECT SINGLE funcname, pname, include
      FROM tfdir
      WHERE funcname = @l_function_module
      INTO @DATA(ls_tfdir).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CALL FUNCTION 'FUNCTION_INCLUDE_CONCATENATE'
      CHANGING
        program                  = ls_tfdir-pname
        complete_area            = r_function_group
      EXCEPTIONS
        not_enough_input         = 0
        no_function_pool         = 0
        delimiter_wrong_position = 0
        OTHERS                   = 0.

  ENDMETHOD.

  METHOD _get_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR e_s_func_data.

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.functions.fmodules.v2+xml' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.
      RETURN.
    ENDIF.

    TRY.

        CALL TRANSFORMATION st_fb_adt_func
          SOURCE XML ls_response-message_body
          RESULT func_data = e_s_func_data.

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

  METHOD _lock.

    DATA: ls_request     TYPE sadt_rest_request,
          ls_response    TYPE sadt_rest_response,
          ls_lock_result TYPE sadt_object_lock_result2.

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }?_action=LOCK&accessMode=MODIFY|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

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

    DATA(l_function_module) = to_lower( condense( i_function_module ) ).

    DATA(l_function_group) = me->_get_function_group( i_function_module ).

    DATA(l_function_group_name) = to_lower( condense( l_function_group ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_module }?_action=UNLOCK&lockHandle={ me->_lock_handle }| ##NO_TEXT.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    REPLACE '&1' IN ls_request-request_line-uri WITH l_function_group_name.

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.
    DATA l_source TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_update) = abap_true.
    DATA(l_get_function_group) = abap_false.
    DATA(l_get_source_code) = abap_false.
    DATA(l_get_properties) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
                       i_function_module   = 'Z_F_YAAI_FC_TST1_2'
                       i_short_description = 'ADT API Test'
                       i_function_group    = 'ZFG_YAAI_FC_TST1'
                       i_transport_request = 'NPLK900125'
                     ).

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_function_module = 'RPY_FUNCTIONMODULE_READ_NEW'
        ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = '$TMP'
*                       i_function_module   =
*                       i_short_description =
                     ).

      WHEN l_update.

        l_source = 'FUNCTION Z_F_YAAI_FC_TST1_2'.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }  IMPORTING|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    i1 TYPE i|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    i2 TYPE string|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }  EXPORTING|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    e1 TYPE i.|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }    e1 = i1.|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }{ cl_abap_char_utilities=>newline }ENDFUNCTION.|.

        l_response = me->update(
                       i_function_module   = 'Z_F_YAAI_FC_TST1_2'
*                       i_short_description =
                       i_transport_request = 'NPLK900125'
                       i_source            = l_source
                     ).

      WHEN l_get_function_group.

        DATA(l_fg) = me->_get_function_group( i_function_module = 'Z_F_YAAI_FC_TST1_1' ).

        l_response = l_fg.


      WHEN l_get_source_code.

        l_response = me->_get_source_code( 'Z_F_YAAI_FC_TST1_1' ).

      WHEN l_get_properties.

        me->_get_properties(
          EXPORTING
            i_function_module = 'Z_F_YAAI_FC_TST1_1'
          IMPORTING
            e_error_message   = DATA(l_error_message)
            e_s_func_data     = DATA(ls_func_data)
        ).

        IF l_error_message IS INITIAL.
          l_response = ls_func_data-description.
        ELSE.
          l_response = l_error_message.
        ENDIF.

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
