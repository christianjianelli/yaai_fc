CLASS ycl_aai_fc_func_group_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'FUGR',
               mc_uri    TYPE string      VALUE '/sap/bc/adt/functions/groups'.

    METHODS read
      IMPORTING
                i_function_group_name TYPE rs38l_area
      RETURNING VALUE(r_response)     TYPE string.

    METHODS create
      IMPORTING
                i_function_group_name TYPE rs38l_area
                i_short_description   TYPE as4text
                i_transport_request   TYPE yde_aai_fc_transport_request
                i_package             TYPE packname
      RETURNING VALUE(r_response)     TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS _get_source_code
      IMPORTING
                i_function_group_name TYPE rs38l_area
      RETURNING VALUE(r_source)       TYPE string.

    METHODS _get_properties
      IMPORTING
        i_function_group_name TYPE rs38l_area
      EXPORTING
        e_error_message       TYPE string
        e_s_fugr_data         TYPE cl_fb_adt_res_fugr=>ty_fugr_data.

    METHODS _is_authorized
      IMPORTING
                i_function_group_name TYPE rs38l_area
                i_mode                TYPE csequence DEFAULT 'SHOW'
      RETURNING VALUE(r_authorized)   TYPE abap_bool.

ENDCLASS.



CLASS ycl_aai_fc_func_group_tools IMPLEMENTATION.

  METHOD read.

    DATA l_source TYPE string.

    DATA(l_function_group_name) = i_function_group_name.

    l_function_group_name = to_upper( condense( l_function_group_name ) ).

    IF me->_is_authorized( l_function_group_name ) = abap_false.
      r_response = |No authorization to read the function group { l_function_group_name } source code.|.
      RETURN.
    ENDIF.

    me->_get_properties(
      EXPORTING
        i_function_group_name = l_function_group_name
      IMPORTING
        e_s_fugr_data  = DATA(ls_fugr_data)
    ).

    l_source = me->_get_source_code( i_function_group_name = l_function_group_name ).

    r_response = |Function Group: { l_function_group_name }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_fugr_data-description }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }```abap|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ l_source }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }```|.

  ENDMETHOD.

  METHOD create.

    DATA: ls_request   TYPE sadt_rest_request,
          ls_response  TYPE sadt_rest_response,
          ls_fugr_data TYPE cl_fb_adt_res_fugr=>ty_fugr_data,
          ls_exc_data  TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    DATA(l_transport_request) = to_upper( condense( i_transport_request ) ).

    ls_request-request_line-method = 'POST' ##NO_TEXT.
    ls_request-request_line-uri = |{ mc_uri }?corrNr={ l_transport_request }|.
    ls_request-request_line-version = 'HTTP/1.1' ##NO_TEXT.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.checkmessages+xml' )
                                        ( name = 'Content-Type'
                                          value = 'application/vnd.sap.adt.functions.groups.v2+xml' ) ).

    ls_fugr_data-description = i_short_description.
    ls_fugr_data-language = sy-langu.
    ls_fugr_data-name = to_upper( condense( i_function_group_name ) ).
    ls_fugr_data-type = 'FUGR/F' ##NO_TEXT.
    ls_fugr_data-responsible = sy-uname.
    ls_fugr_data-master_system = sy-sysid.
    ls_fugr_data-master_language = sy-langu.
    ls_fugr_data-package_ref-name = to_upper( condense( i_package ) ).

    TRY.

        CALL TRANSFORMATION st_fb_adt_fugr
          SOURCE
            fugr_data = ls_fugr_data
          RESULT XML
            ls_request-message_body.

      CATCH cx_transformation_error.

        r_response = |An error occured while creating the function group { i_function_group_name }.|.

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

    r_response = |Function Group { i_function_group_name } created successfully!|.

  ENDMETHOD.

  METHOD _get_source_code.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response.

    DATA(l_function_group_name) = to_lower( condense( i_function_group_name ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_group_name }/source/main|.
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

  METHOD _get_properties.

    DATA: ls_request  TYPE sadt_rest_request,
          ls_response TYPE sadt_rest_response,
          ls_exc_data TYPE sadt_exception.

    DATA l_langu TYPE t002-laiso.

    CLEAR e_s_fugr_data.

    DATA(l_function_group_name) = to_lower( condense( i_function_group_name ) ).

    ls_request-request_line-method = 'GET'.
    ls_request-request_line-uri = |{ me->mc_uri }/{ l_function_group_name }|.
    ls_request-request_line-version = 'HTTP/1.1'.

    ls_request-header_fields = VALUE #( ( name = 'Accept'
                                          value = 'application/vnd.sap.adt.functions.groups.v2+xml' ) ).

    CALL FUNCTION 'SADT_REST_RFC_ENDPOINT'
      EXPORTING
        request  = ls_request
      IMPORTING
        response = ls_response.

    IF ls_response-message_body IS INITIAL.
      RETURN.
    ENDIF.

    TRY.

        CALL TRANSFORMATION st_fb_adt_fugr
          SOURCE XML ls_response-message_body
          RESULT fugr_data = e_s_fugr_data.

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

  METHOD _is_authorized.

    "Mode ('INSERT','MODIFY','SHOW','FREE')

    r_authorized = abap_true.

    CALL FUNCTION 'RS_ACCESS_PERMISSION'
      EXPORTING
        mode                     = i_mode
        object                   = i_function_group_name
        object_class             = mc_object
        suppress_corr_check      = abap_true
        suppress_language_check  = abap_true
        suppress_extend_dialog   = abap_true
      EXCEPTIONS
        canceled_in_corr         = 1
        enqueued_by_user         = 2
        enqueue_system_failure   = 3
        illegal_parameter_values = 4
        locked_by_author         = 5
        no_modify_permission     = 6
        no_show_permission       = 7
        permission_failure       = 8
        request_language_denied  = 9
        OTHERS                   = 10.

    IF sy-subrc <> 0.
      r_authorized = abap_false.
    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_create) = abap_true.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_function_group_name = 'ZFG_DEBUG_ADT'
        ).

      WHEN l_search.

      WHEN l_create.

        l_response = me->create( i_function_group_name = 'ZFG_YAAI_FC_TST1'
                                 i_short_description   = 'Test create tool'
                                 i_transport_request   = 'NPLK900125'
                                 i_package             = 'Z001'
                               ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.
ENDCLASS.
