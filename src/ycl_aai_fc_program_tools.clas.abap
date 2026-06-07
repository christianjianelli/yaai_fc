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

    IF me->_is_authorized( i_program_name ) = abap_false.
      r_response = |No authorization to read the program/include { i_program_name } source code.|.
      RETURN.
    ENDIF.

    READ REPORT i_program_name INTO lt_source.

    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<l_line>).

      IF l_source IS INITIAL.
        l_source = <l_line> && cl_abap_char_utilities=>newline.
      ELSE.
        l_source = l_source  && <l_line> && cl_abap_char_utilities=>newline.
      ENDIF.

    ENDLOOP.

    r_response = l_source.

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

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_true.
    DATA(l_search) = abap_false.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_program_name = 'ZRXX_REPORT_TEMPLATE_C01'
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
