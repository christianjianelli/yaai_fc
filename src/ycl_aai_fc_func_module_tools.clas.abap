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

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _is_authorized
      IMPORTING
                i_function_module   TYPE rs38l_fnam
      RETURNING VALUE(r_authorized) TYPE abap_bool.

    METHODS _get_source_code
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_source)   TYPE string.

    METHODS _get_function_group
      IMPORTING
                i_function_module       TYPE rs38l_fnam
      RETURNING VALUE(r_function_group) TYPE rs38l_area.

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

  METHOD _is_authorized.

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

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_get_function_group) = abap_false.
    DATA(l_get_source_code) = abap_true.


    CASE abap_true.

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

      WHEN l_get_function_group.

        DATA(l_fg) = me->_get_function_group( i_function_module = 'Z_F_YAAI_FC_TST1_1' ).

        l_response = l_fg.


      WHEN l_get_source_code.

        l_response = me->_get_source_code( 'Z_F_YAAI_FC_TST1_1' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
