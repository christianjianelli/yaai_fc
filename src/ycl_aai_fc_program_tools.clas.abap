CLASS ycl_aai_fc_program_tools DEFINITION
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
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_program_name      TYPE programm OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS syntax_check
      IMPORTING
                i_program_name    TYPE programm
      RETURNING VALUE(r_response) TYPE string.

    METHODS calculate_start_end
      IMPORTING
        i_cursor_line TYPE i
        i_lines       TYPE i
        i_max_lines   TYPE i DEFAULT 10
      EXPORTING
        e_start_line  TYPE i
        e_end_line    TYPE i.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _is_authorized
      IMPORTING
                i_program_name      TYPE programm
      RETURNING VALUE(r_authorized) TYPE abap_bool.

ENDCLASS.



CLASS ycl_aai_fc_program_tools IMPLEMENTATION.

  METHOD read.

    DATA lt_source TYPE ty_string_t.

    DATA l_source TYPE string.

    DATA(l_program_name) = i_program_name.

    l_program_name = to_upper( condense( l_program_name ) ).

    IF me->_is_authorized( l_program_name ) = abap_false.
      r_response = |No authorization to read the program/include { i_program_name } source code.|.
      RETURN.
    ENDIF.

    READ REPORT l_program_name INTO lt_source.

    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<l_line>).

      IF l_source IS INITIAL.
        l_source = <l_line> && cl_abap_char_utilities=>newline.
      ELSE.
        l_source = l_source  && <l_line> && cl_abap_char_utilities=>newline.
      ENDIF.

    ENDLOOP.

    r_response = l_source.

  ENDMETHOD.

  METHOD search.

    DATA: l_program           TYPE string,
          l_short_description TYPE string.

    CLEAR r_response.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    SELECT pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND devclass = @l_package
      INTO TABLE @DATA(lt_tadir).

    IF sy-subrc <> 0.
      r_response = |No program found in package { l_package }.|.
      RETURN.
    ENDIF.

    l_program = |*{ i_program_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_program IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_program.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      SELECT SINGLE name, sprsl, text
        FROM trdirt
        INTO @DATA(ls_trdirt)
        WHERE name = @<ls_tadir>-obj_name
          AND sprsl = @sy-langu.

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_trdirt-text CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      r_response = |{ r_response }Program: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_trdirt-text }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |No program found in package { l_package }.|.
    ENDIF.

  ENDMETHOD.

  METHOD syntax_check.

    DATA lt_source TYPE ty_string_t.

    DATA lt_errors TYPE STANDARD TABLE OF rslinlmsg.

    DATA: l_source        TYPE string,
          l_error_message TYPE c LENGTH 200,
          l_error_include TYPE sy-repid,
          l_error_line    TYPE sy-subrc,
          l_error_offset  TYPE sy-tabix,
          l_error_subrc   TYPE sy-subrc.

    DATA(l_program_name) = i_program_name.

    l_program_name = to_upper( condense( l_program_name ) ).

    IF me->_is_authorized( l_program_name ) = abap_false.
      r_response = |No authorization to read the program/include { i_program_name } source code.|.
      RETURN.
    ENDIF.

    READ REPORT l_program_name INTO lt_source STATE 'I'. "Inactive version

    IF lt_source IS INITIAL.
      READ REPORT l_program_name INTO lt_source. "Active version
    ENDIF.

    CALL FUNCTION 'EDITOR_SYNTAX_CHECK'
      EXPORTING
        i_program       = l_program_name
      IMPORTING
        o_error_include = l_error_include
        o_error_line    = l_error_line
        o_error_message = l_error_message
        o_error_offset  = l_error_offset
        o_error_subrc   = l_error_subrc
      TABLES
        i_source        = lt_source
        o_error_tab     = lt_errors.

    IF l_error_subrc <> 0.

      l_error_line = l_error_line - 2.

      r_response = |Syntax error found{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Program/Include: { i_program_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Reported line: { l_error_line }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Error message: { cl_abap_char_utilities=>newline }{ l_error_message }{ cl_abap_char_utilities=>newline }|.

      me->calculate_start_end(
        EXPORTING
          i_cursor_line = l_error_line
          i_lines       = lines( lt_source )
        IMPORTING
          e_start_line  = DATA(l_start_line)
          e_end_line    = DATA(l_end_line)
      ).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Code context:{ cl_abap_char_utilities=>newline }|.

      LOOP AT lt_source FROM l_start_line TO l_end_line
        ASSIGNING FIELD-SYMBOL(<l_line>).

        r_response = |{ r_response }{ sy-tabix }:{ <l_line> }{ cl_abap_char_utilities=>newline }|.

      ENDLOOP.

    ELSE.

      r_response = |No errors found in program { i_program_name }|.

    ENDIF.

  ENDMETHOD.

  METHOD _is_authorized.

    r_authorized = abap_true.

    CALL FUNCTION 'RS_ACCESS_PERMISSION'
      EXPORTING
        mode                     = 'SHOW'
        object                   = i_program_name
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

  METHOD calculate_start_end.

    " If the total number of lines is less than or equal to the max lines,
    " the range is simply the entire file.
    IF i_lines <= i_max_lines.
      e_start_line = 1.
      e_end_line = i_lines.
      RETURN.
    ENDIF.

    " Calculate how many lines to take before and after the cursor.
    " DIV performs integer division (it discards the remainder), which is
    " equivalent to floor().
    DATA(l_lines_before) = ( i_max_lines - 1 ) DIV 2.
    DATA(l_lines_after)  = i_max_lines - 1 - l_lines_before.

    " Calculate the initial ideal start and end lines.
    DATA(l_start_line) = i_cursor_line - l_lines_before.
    DATA(l_end_line)   = i_cursor_line + l_lines_after.

    " Adjust the range if it goes out of the file's boundaries.
    IF l_start_line < 1.
      " CASE 1: Cursor is near the beginning of the file.
      e_start_line = 1.
      e_end_line = i_max_lines.
    ELSEIF l_end_line > i_lines.
      " CASE 2: Cursor is near the end of the file.
      e_end_line = i_lines.
      e_start_line = i_lines - i_max_lines + 1.
    ELSE.
      " CASE 3: The ideal range is valid and within boundaries.
      e_start_line = l_start_line.
      e_end_line = l_end_line.
    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_check) = abap_true.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_program_name = 'ZCHRJS00'
        ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = 'Z001'
*                       i_program_name      =
*                       i_short_description =
                     ).

      WHEN l_check.

        l_response = me->syntax_check(
          EXPORTING
            i_program_name = 'ZCHRJS00'
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
