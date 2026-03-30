CLASS ycl_aai_fc_ddic_tools_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS determine_data_type
      IMPORTING
        i_data_type TYPE csequence
      EXPORTING
        e_data_type TYPE datatype_d
        e_error     TYPE string.

    METHODS get_built_in_types_supported
      RETURNING VALUE(r_response) TYPE string.

    METHODS get_built_in_types_response
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_ddic_tools_util IMPLEMENTATION.

  METHOD get_built_in_types_supported.
    r_response = 'The ABAP built-in types supported are: CHAR, INT1, INT2, INT4, DEC, NUMC, STRING, DATS, TIMS, QUAN, UNIT, CURR, CUKY, FLTP, LANG, CLNT.'.
    r_response = |{ cl_abap_char_utilities=>newline }{ r_response }The types: CHAR AND NUMC require a length.|.
    r_response = |{ cl_abap_char_utilities=>newline }{ r_response }The types: DEC, QUAN and CURR require a length and decimals, where decimals can be zero.|.
    r_response = |{ cl_abap_char_utilities=>newline }{ r_response }The type STRING can have a length but it must be greater than or equal to 256, or 0 for a string with unlimited length.|.
  ENDMETHOD.

  METHOD get_built_in_types_response.
    r_response = 'The ABAP built-in types supported are: CHAR, INT1, INT2, INT4, DEC, NUMC, STRING, DATS, TIMS, QUAN, UNIT, CURR, CUKY, FLTP, LANG, CLNT'.
  ENDMETHOD.

  METHOD determine_data_type.

    CLEAR e_data_type.

    DATA(l_data_type) = condense( to_upper( i_data_type ) ).

    CASE l_data_type.

      WHEN 'CHAR' OR
           'INT1' OR
           'INT2' OR
           'INT4' OR
           'DEC'  OR
           'NUMC' OR
           'QUAN' OR
           'UNIT' OR
           'CURR' OR
           'CUKY' OR
           'DATS' OR
           'TIMS' OR
           'FLTP' OR
           'LANG' OR
           'CLNT'.

        e_data_type = l_data_type.

      WHEN 'STRING'.

        e_data_type = 'STRG'.

      WHEN OTHERS.

        RETURN.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
