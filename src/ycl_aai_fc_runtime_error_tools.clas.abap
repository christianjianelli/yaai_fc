CLASS ycl_aai_fc_runtime_error_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_dumpinfo_s,
             sydate       TYPE sydatum,
             sytime       TYPE syuzeit,
             syhost       TYPE syhost,
             syuser       TYPE syuname,
             mandt        TYPE mandt,
             modno        TYPE sywpid,
             program_name TYPE progname,
             subc         TYPE subc,
             include_name TYPE progname,
             line_number  TYPE abp_sline,
             shorttext    TYPE string,
             explanation  TYPE string,
             description  TYPE string,
             source_code  TYPE string,
           END OF ty_dumpinfo_s,

           ty_dumpinfo_t TYPE STANDARD TABLE OF ty_dumpinfo_s.

    INTERFACES if_oo_adt_classrun.

    METHODS get_runtime_errors
      IMPORTING
                i_date            TYPE yde_aai_fc_date
                i_time_from       TYPE yde_aai_fc_time OPTIONAL
                i_time_to         TYPE yde_aai_fc_time OPTIONAL
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA _max_lines TYPE i VALUE 30.

    METHODS _get_runtime_errors
      IMPORTING
        i_date             TYPE yde_aai_fc_date
        i_time_from        TYPE yde_aai_fc_time OPTIONAL
        i_time_to          TYPE yde_aai_fc_time OPTIONAL
      EXPORTING
        e_t_runtime_errors TYPE ty_dumpinfo_t.

    METHODS _get_method_name_from_include
      IMPORTING
        i_include     TYPE clike
      EXPORTING
        e_method_name TYPE clike.

    METHODS _get_abap_program_type
      IMPORTING
                i_prog_name   TYPE clike
      RETURNING VALUE(r_subc) TYPE subc.

    METHODS _get_source_code_extract
      IMPORTING
                i_prog_name                  TYPE clike
                i_line_number                TYPE i
      RETURNING VALUE(r_source_code_extract) TYPE string.

    METHODS _calculate_start_end
      IMPORTING
        i_cursor_line TYPE i
        i_lines       TYPE i
      EXPORTING
        e_start_line  TYPE i
        e_end_line    TYPE i.

ENDCLASS.



CLASS ycl_aai_fc_runtime_error_tools IMPLEMENTATION.

  METHOD get_runtime_errors.

    me->_get_runtime_errors(
      EXPORTING
        i_date             = i_date
      IMPORTING
        e_t_runtime_errors = DATA(lt_runtime_errors)
    ).

    IF lt_runtime_errors IS INITIAL.

      r_response = 'No runtime errors found.'.

      RETURN.

    ENDIF.

    LOOP AT lt_runtime_errors ASSIGNING FIELD-SYMBOL(<ls_runtime_errors>).

      IF r_response IS NOT INITIAL.
        r_response = r_response && cl_abap_char_utilities=>newline.
      ENDIF.

      <ls_runtime_errors>-subc = me->_get_abap_program_type( <ls_runtime_errors>-program_name ).

      IF <ls_runtime_errors>-subc = 'K'.

        DATA(l_class_name) = cl_oo_classname_service=>get_clsname_by_include( incname = <ls_runtime_errors>-program_name ).

        <ls_runtime_errors>-program_name = l_class_name.

        me->_get_method_name_from_include(
          EXPORTING
            i_include     = <ls_runtime_errors>-include_name
          IMPORTING
            e_method_name = <ls_runtime_errors>-include_name ).

        r_response = |{ r_response }Class: { <ls_runtime_errors>-program_name }{ cl_abap_char_utilities=>newline }|.
        r_response = |{ r_response }Method: { <ls_runtime_errors>-include_name }{ cl_abap_char_utilities=>newline }|.

      ELSE.

        r_response = |{ r_response }Program: { <ls_runtime_errors>-program_name }{ cl_abap_char_utilities=>newline }|.
        r_response = |{ r_response }Include: { <ls_runtime_errors>-include_name }{ cl_abap_char_utilities=>newline }|.

      ENDIF.

      r_response = |{ r_response }Line Number: { <ls_runtime_errors>-line_number }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Short Text: { <ls_runtime_errors>-shorttext }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Explanation: { <ls_runtime_errors>-explanation }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { <ls_runtime_errors>-description }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Source code extract: { cl_abap_char_utilities=>newline }{ <ls_runtime_errors>-source_code }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD _get_runtime_errors.

    DATA: lt_ft        TYPE rsdump_ft_it,
          lt_rng_uzeit TYPE RANGE OF tims.

    FREE e_t_runtime_errors.

    IF i_time_from IS NOT INITIAL AND i_time_to IS INITIAL.
      APPEND VALUE #( sign = 'I' option = 'GE' low = i_time_from ) TO lt_rng_uzeit.
    ENDIF.

    IF i_time_from IS NOT INITIAL AND i_time_to IS NOT INITIAL.
      APPEND VALUE #( sign = 'I' option = 'BT' low = i_time_from high = i_time_to ) TO lt_rng_uzeit.
    ENDIF.

    SELECT datum, uzeit, ahost, uname, mandt, modno, seqno
      FROM snap
      INTO TABLE @DATA(lt_snap)
      WHERE datum = @i_date
      AND uzeit IN @lt_rng_uzeit
      AND mandt = @sy-mandt
      AND seqno = '000'.

    LOOP AT lt_snap ASSIGNING FIELD-SYMBOL(<ls_snap>).

      APPEND INITIAL LINE TO e_t_runtime_errors ASSIGNING FIELD-SYMBOL(<ls_runtime_error>).

      <ls_runtime_error>-sydate = <ls_snap>-datum.
      <ls_runtime_error>-sytime = <ls_snap>-uzeit.
      <ls_runtime_error>-syhost = <ls_snap>-ahost.
      <ls_runtime_error>-syuser = <ls_snap>-uname.
      <ls_runtime_error>-mandt  = <ls_snap>-mandt.
      <ls_runtime_error>-modno  = <ls_snap>-modno.

      CALL FUNCTION 'RS_ST22_GET_FT'
        EXPORTING
          datum = <ls_snap>-datum
          uzeit = <ls_snap>-uzeit
          uname = <ls_snap>-uname
          ahost = <ls_snap>-ahost
          modno = <ls_snap>-modno
          mandt = <ls_snap>-mandt
        IMPORTING
          ft    = lt_ft.

      CALL FUNCTION 'RS_ST22_READ_SNAPT'
        IMPORTING
          shorttext   = <ls_runtime_error>-shorttext
          explanation = <ls_runtime_error>-explanation
          description = <ls_runtime_error>-description.

      READ TABLE lt_ft ASSIGNING FIELD-SYMBOL(<ls_ft>)
        WITH KEY id = 'AP'.

      IF sy-subrc = 0.
        <ls_runtime_error>-program_name = <ls_ft>-value.
      ENDIF.

      READ TABLE lt_ft ASSIGNING <ls_ft>
        WITH KEY id = 'AI'.

      IF sy-subrc = 0.
        <ls_runtime_error>-include_name = <ls_ft>-value.
      ENDIF.

      READ TABLE lt_ft ASSIGNING <ls_ft>
        WITH KEY id = 'AL'.

      IF sy-subrc = 0.
        <ls_runtime_error>-line_number = <ls_ft>-value.
      ENDIF.

    ENDLOOP.

    SORT e_t_runtime_errors BY program_name include_name line_number.

    DELETE ADJACENT DUPLICATES FROM e_t_runtime_errors COMPARING program_name include_name line_number.

    LOOP AT e_t_runtime_errors ASSIGNING <ls_runtime_error>.

      <ls_runtime_error>-source_code = me->_get_source_code_extract(
        EXPORTING
          i_prog_name = COND #( WHEN <ls_runtime_error>-include_name IS NOT INITIAL
                                          THEN <ls_runtime_error>-include_name
                                          ELSE <ls_runtime_error>-program_name )
          i_line_number = CONV #( <ls_runtime_error>-line_number )
      ).

    ENDLOOP.

  ENDMETHOD.

  METHOD _get_method_name_from_include.

    DATA: lo_clif_incl_naming TYPE REF TO if_oo_clif_incl_naming,
          lo_include_naming   TYPE REF TO if_oo_class_incl_naming.

    DATA: l_progname    TYPE programm,
          l_method_name TYPE seocpdname.

    l_progname = i_include.

    cl_oo_include_naming=>get_instance_by_include(
        EXPORTING
          progname       =  l_progname               " Include Name
        RECEIVING
          cifref         =  lo_clif_incl_naming
        EXCEPTIONS
          no_objecttype  = 1
          internal_error = 2
          OTHERS         = 3 ).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lo_include_naming ?= lo_clif_incl_naming.

    lo_include_naming->get_mtdname_by_include(
      EXPORTING
        progname                     =  l_progname                " Include Name
      RECEIVING
        mtdname                      =  l_method_name
      EXCEPTIONS
        wrong_class                  = 1
        internal_method_not_existing = 2
        OTHERS                       = 3
    ).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    e_method_name = l_method_name.

  ENDMETHOD.

  METHOD _get_abap_program_type.

    SELECT SINGLE subc
      FROM progdir
      INTO r_subc
      WHERE name = i_prog_name
        AND state = 'A'.

*    SUBC values meaning
*    1   Executable program
*    I   INCLUDE program
*    M   Module Pool
*    F   Function group
*    S   Subroutine Pool
*    J   Interface pool
*    K   Class pool
*    T   Type Pool
*    X   Transformation (XSLT or ST Program)
*    Q   Database Procedure Proxy

  ENDMETHOD.

  METHOD _get_source_code_extract.

    DATA lt_read_report_source TYPE TABLE OF string.

    DATA l_line TYPE string.

    FREE r_source_code_extract.

    READ REPORT i_prog_name INTO lt_read_report_source.

    IF lt_read_report_source IS INITIAL.
      RETURN.
    ENDIF.

    me->_calculate_start_end(
      EXPORTING
        i_cursor_line = i_line_number
        i_lines       = lines( lt_read_report_source )
      IMPORTING
        e_start_line  = DATA(l_start_line)
        e_end_line    = DATA(l_end_line)
    ).

    LOOP AT lt_read_report_source ASSIGNING FIELD-SYMBOL(<ls_line>)
      FROM l_start_line TO l_end_line.

      DATA(l_line_number) = sy-tabix.

      IF r_source_code_extract IS NOT INITIAL.
        r_source_code_extract = r_source_code_extract && cl_abap_char_utilities=>newline.
      ENDIF.

      FREE l_line.

      l_line = |Line { l_line_number }:|.

      IF l_line_number = i_line_number.

        l_line = repeat( val = '>' occ = ( strlen( l_line ) - 1 ) ).

        l_line = l_line && ':'.

      ENDIF.

      r_source_code_extract = |{ r_source_code_extract }{ l_line } { <ls_line> }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD _calculate_start_end.

    " If the total number of lines is less than or equal to the max lines,
    " the range is simply the entire file.
    IF i_lines <= me->_max_lines.
      e_start_line = 1.
      e_end_line = i_lines.
      RETURN.
    ENDIF.

    " Calculate how many lines to take before and after the cursor.
    " DIV performs integer division (it discards the remainder), which is
    " equivalent to floor().
    DATA(l_lines_before) = ( me->_max_lines - 1 ) DIV 2.
    DATA(l_lines_after)  = me->_max_lines - 1 - l_lines_before.

    " Calculate the initial ideal start and end lines.
    DATA(l_start_line) = i_cursor_line - l_lines_before.
    DATA(l_end_line)   = i_cursor_line + l_lines_after.

    " Adjust the range if it goes out of the file's boundaries.
    IF l_start_line < 1.
      " CASE 1: Cursor is near the beginning of the file.
      e_start_line = 1.
      e_end_line = me->_max_lines.
    ELSEIF l_end_line > i_lines.
      " CASE 2: Cursor is near the end of the file.
      e_end_line = i_lines.
      e_start_line = i_lines - me->_max_lines + 1.
    ELSE.
      " CASE 3: The ideal range is valid and within boundaries.
      e_start_line = l_start_line.
      e_end_line = l_end_line.
    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_get_runtime_errors) = abap_true.

    CASE abap_true.

      WHEN l_get_runtime_errors.

        l_response = me->get_runtime_errors(
                       i_date = '20260513'
                       i_time_from = '070000'
                       i_time_to   = '080000'
                     ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
