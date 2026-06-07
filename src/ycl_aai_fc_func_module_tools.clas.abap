CLASS ycl_aai_fc_func_module_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'PROG'.

    TYPES ty_string_t TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS read
      IMPORTING
                i_function_module TYPE rs38l_fnam
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _is_authorized
      IMPORTING
                i_function_module   TYPE rs38l_fnam
      RETURNING VALUE(r_authorized) TYPE abap_bool.

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

  METHOD _is_authorized.

    r_authorized = abap_true.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_true.
    DATA(l_search) = abap_false.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_function_module = 'RPY_FUNCTIONMODULE_READ_NEW'
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
