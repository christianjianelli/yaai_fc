CLASS ycl_aai_fc_transaction_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'TRAN'.

    METHODS create_report_transaction
      IMPORTING
                i_transaction_code  TYPE tcode
                i_short_description TYPE ttext_stct
                i_program           TYPE programm
                i_package           TYPE packname
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS create_dialog_transaction
      IMPORTING
                i_transaction_code  TYPE tcode
                i_short_description TYPE ttext_stct
                i_program           TYPE programm
                i_screen_number     TYPE scradnum
                i_package           TYPE packname
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_transaction_code TYPE tcode
      RETURNING VALUE(r_response)  TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_transaction_code  TYPE tcode OPTIONAL
                i_short_description TYPE ttext_stct OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_transaction_code  TYPE tcode
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS set_translation
      IMPORTING
                i_transaction_code  TYPE tcode
                i_short_description TYPE as4text
                i_transport_request TYPE yde_aai_fc_transport_request
                i_language          TYPE spras
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_translation
      IMPORTING
                i_transaction_code TYPE tcode
                i_language         TYPE spras
      RETURNING VALUE(r_response)  TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _create
      IMPORTING
                i_transaction_code  TYPE tcode
                i_short_description TYPE ttext_stct
                i_transaction_type  TYPE rglif-docutype
                i_program           TYPE programm
                i_screen_number     TYPE scradnum OPTIONAL
                i_package           TYPE packname
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

ENDCLASS.



CLASS ycl_aai_fc_transaction_tools IMPLEMENTATION.

  METHOD create_report_transaction.

    r_response = me->_create(
      EXPORTING
        i_transaction_code  = i_transaction_code
        i_short_description = i_short_description
        i_transaction_type  = ststc_c_type_report
        i_program           = i_program
        i_package           = i_package
        i_transport_request = i_transport_request
    ).

  ENDMETHOD.

  METHOD create_dialog_transaction.

    r_response = me->_create(
      EXPORTING
        i_transaction_code  = i_transaction_code
        i_short_description = i_short_description
        i_transaction_type  = ststc_c_type_dialog
        i_program           = i_program
        i_package           = i_package
        i_transport_request = i_transport_request
    ).

  ENDMETHOD.

  METHOD read.

    CLEAR r_response.

    DATA(l_transaction) = i_transaction_code.

    l_transaction = condense( to_upper( l_transaction ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_transaction
      INTO @DATA(ls_tadir).

    SELECT a~tcode, a~pgmna, a~dypno, b~ttext
      FROM tstc AS a
      LEFT OUTER JOIN tstct AS b
      ON a~tcode = b~tcode
      AND b~sprsl = @sy-langu
      WHERE a~tcode = @l_transaction
      INTO TABLE @DATA(lt_transaction).

    IF sy-subrc <> 0.
      r_response = |Transaction { l_transaction } not found.|.
      RETURN.
    ENDIF.

    LOOP AT lt_transaction ASSIGNING FIELD-SYMBOL(<ls_transaction>).

      r_response = |Transaction: { l_transaction }|.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { <ls_transaction>-ttext }|.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Program: { <ls_transaction>-pgmna }|.

      IF <ls_transaction>-dypno <> '1000'.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Screen: { <ls_transaction>-dypno }|.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Type: D (Program and Dynpro - Dialog Transaction)|.
      ELSE.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Type: R (Program and Selection Screen - Report Transaction)|.
      ENDIF.

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Package: { ls_tadir-devclass }|.

      EXIT.

    ENDLOOP.

  ENDMETHOD.

  METHOD search.

    CLEAR r_response.

    DATA(l_transaction) = i_transaction_code.

    l_transaction = condense( to_upper( l_transaction ) ).

    SELECT a~tcode, a~pgmna, a~dypno, b~ttext
      FROM tstc AS a
      LEFT OUTER JOIN tstct AS b
      ON a~tcode = b~tcode
      AND b~sprsl = @sy-langu
      WHERE a~tcode = @l_transaction
      INTO TABLE @DATA(lt_transaction).

    IF sy-subrc <> 0.
      r_response = |No transaction found.|.
      RETURN.
    ENDIF.


  ENDMETHOD.

  METHOD delete.

    CLEAR r_response.

    DATA(l_transaction) = i_transaction_code.

    l_transaction = condense( to_upper( l_transaction ) ).

    SELECT SINGLE @abap_true
      FROM tstc
      WHERE tcode = @l_transaction
      INTO @DATA(l_exists).

    IF sy-subrc <> 0.
      r_response = |Transaction { l_transaction } not found.|.
      RETURN.
    ENDIF.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    CALL FUNCTION 'RPY_TRANSACTION_DELETE'
      EXPORTING
        transaction      = l_transaction
        transport_number = l_transport_request
*       suppress_authority_check = space            " Single-Character Flag
*       suppress_corr_insert     = space            " Single-Character Flag
      EXCEPTIONS
        not_excecuted    = 1
        object_not_found = 2
        OTHERS           = 3.

    IF sy-subrc = 0.
      r_response = |Transaction { l_transaction } deleted successfully.|.
    ELSE.
      r_response = |An error occurred while deleting the transaction { l_transaction }.|.
    ENDIF.

  ENDMETHOD.

  METHOD get_translation.

    CLEAR r_response.

    DATA(l_transaction) = i_transaction_code.

    l_transaction = condense( to_upper( l_transaction ) ).

    DATA(l_language) = i_language.

    l_language = to_upper( l_language ).

    SELECT SINGLE @abap_true
      FROM tstc
      WHERE tcode = @l_transaction
      INTO @DATA(l_exists).

    IF sy-subrc <> 0.
      r_response = |Transaction { l_transaction } not found.|.
      RETURN.
    ENDIF.

    SELECT SINGLE sprsl, tcode, ttext
      FROM tstct
      WHERE sprsl = @l_language
        AND tcode = @l_transaction
      INTO @DATA(ls_tstct).

    IF sy-subrc <> 0.
      r_response = |No translation found for transaction { l_transaction } in language { l_language }.|.
      RETURN.
    ENDIF.

    r_response = |Transaction: { l_transaction }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_tstct-ttext }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Language: { ls_tstct-sprsl }|.

  ENDMETHOD.

  METHOD set_translation.

    DATA: lt_pcx_s1      TYPE STANDARD TABLE OF lxe_pcx_s1,
          lt_pcx_s1_valu TYPE STANDARD TABLE OF lxe_pcx_s1,
          lt_e071        TYPE trwbo_t_e071.

    DATA: l_custmnr TYPE lxecustmnr VALUE '999999',
          l_objtype TYPE trobjtype VALUE mc_object,
          l_objname TYPE lxeobjname,
          l_status  TYPE lxestatprc,
          l_error   TYPE lxestring,
          l_textkey TYPE lxe_pcx_s1-textkey.

    CLEAR r_response.

    DATA(l_transaction) = i_transaction_code.

    l_transaction = condense( to_upper( l_transaction ) ).

    l_objname = l_transaction.

    DATA(l_language) = i_language.

    l_language = to_upper( l_language ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
     FROM tadir
     WHERE pgmid = @mc_pgmid
       AND object = @mc_object
       AND obj_name = @l_transaction
     INTO @DATA(ls_tadir).

    SELECT language, r3_lang
      FROM lxe_t002x
      WHERE r3_lang = @ls_tadir-masterlang
      AND is_r3_lang = 'X'
      AND langshort <> ''
      INTO @DATA(ls_source_language)
      UP TO 1 ROWS.
    ENDSELECT.

    SELECT language, r3_lang, langshort
      FROM lxe_t002x
      WHERE r3_lang = @l_language
      AND is_r3_lang = 'X'
      AND langshort <> ''
      INTO @DATA(ls_target_language)
      UP TO 1 ROWS.
    ENDSELECT.

    CALL FUNCTION 'LXE_OBJ_TEXT_PAIR_READ'
      EXPORTING
        t_lang    = ls_target_language-language
        s_lang    = ls_source_language-language
        custmnr   = l_custmnr
        objtype   = l_objtype
        objname   = l_objname
      TABLES
        lt_pcx_s1 = lt_pcx_s1.

    IF lt_pcx_s1 IS INITIAL.
      r_response = |Error updating translations. Transaction: { l_transaction }. Target language: { l_language }.|.
      RETURN.
    ENDIF.

    LOOP AT lt_pcx_s1 ASSIGNING FIELD-SYMBOL(<ls_pcx_s1>).
      <ls_pcx_s1>-t_text = i_short_description.
    ENDLOOP.

    CALL FUNCTION 'LXE_OBJ_TEXT_PAIR_WRITE'
      EXPORTING
        s_lang    = ls_source_language-language
        t_lang    = ls_target_language-language
        custmnr   = l_custmnr
        objtype   = l_objtype
        objname   = l_objname
      IMPORTING
        pstatus   = l_status
        err_msg   = l_error
      TABLES
        lt_pcx_s1 = lt_pcx_s1.

    IF l_status <> 'S'.
      r_response = |Error updating translations. Transaction: { l_transaction }. Target language: { l_language }.|.
      RETURN.
    ENDIF.

    lt_e071 = VALUE #( ( trkorr = l_transport_request
                         pgmid = 'LANG'
                         object = 'TRAN'
                         obj_name = l_transaction
                         lang = l_language ) ).

    DATA(l_success) = NEW ycl_aai_fc_cts_api( )->add_object(
      EXPORTING
        i_transport_request = l_transport_request
      CHANGING
        ch_t_e071           = lt_e071
    ).

    IF l_success = abap_true.
      r_response = |Translations updated successfully. Transaction: { l_transaction }. Target language: { l_language }.|.
    ELSE.
      r_response = |Translations updated successfully but they were not added to the transport request { l_transport_request }. Transaction: { l_transaction }. Target language: { l_language }.|.
    ENDIF.

  ENDMETHOD.

  METHOD _create.

    CLEAR r_response.

    DATA(l_transaction) = i_transaction_code.

    l_transaction = condense( to_upper( l_transaction ) ).

    DATA(l_program) = i_program.

    l_program = condense( to_upper( l_program ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    CALL FUNCTION 'RPY_TRANSACTION_INSERT'
      EXPORTING
        transaction         = l_transaction
        program             = l_program
        dynpro              = CONV sychar04( i_screen_number )
        development_class   = l_package
        transport_number    = l_transport_request
        transaction_type    = i_transaction_type
        shorttext           = i_short_description
        html_enabled        = abap_true
        java_enabled        = abap_true
        wingui_enabled      = abap_true
      EXCEPTIONS
        cancelled           = 1
        already_exist       = 2
        permission_error    = 3
        name_not_allowed    = 4
        name_conflict       = 5
        illegal_type        = 6
        object_inconsistent = 7
        db_access_error     = 8
        OTHERS              = 9.

    IF sy-subrc = 0.
      r_response = |Transaction { l_transaction } created successfully.|.
    ELSE.
      r_response = |An error occurred while creating the transaction { l_transaction }.|.
    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_delete) = abap_true.
    DATA(l_read) = abap_false.
    DATA(l_get_translation) = abap_false.
    DATA(l_set_translation) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create_report_transaction(
           EXPORTING
             i_transaction_code  = 'ZTRANS3'
             i_short_description = 'Test FC API'
             i_program           = 'ZCHRJS00'
             i_package           = 'Z001'
             i_transport_request = 'NPLK900137'
         ).

      WHEN l_read.

        l_response = me->read( 'ZTRANS3' ).

      WHEN l_delete.

        l_response = me->delete(
          EXPORTING
            i_transaction_code  = 'ZTRANS3'
            i_transport_request = 'NPLK900137'
        ).

      WHEN l_get_translation.

        l_response = me->get_translation(
                       i_transaction_code = 'ZTRANS3'
                       i_language         = 'P'
                     ).

      WHEN l_set_translation.

        l_response = me->set_translation(
                       i_transaction_code  = 'ZTRANS3'
                       i_short_description = 'Teste tradução PT'
                       i_transport_request = 'NPLK900137'
                       i_language          = 'P'
                     ).

      WHEN OTHERS.

        l_response = 'No test option selected'.

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
