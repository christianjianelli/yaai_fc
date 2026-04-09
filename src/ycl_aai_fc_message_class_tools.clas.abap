CLASS ycl_aai_fc_message_class_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'MSAG'.

    METHODS create
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_description       TYPE as4text
                i_package           TYPE packname
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS add_message
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno OPTIONAL
                i_message_text      TYPE natxt
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update_message
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno
                i_message_text      TYPE natxt
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete_message
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read_all_messages
      IMPORTING
                i_message_class   TYPE yde_aai_fc_message_class
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _get_next_number
      IMPORTING
                i_message_class         TYPE yde_aai_fc_message_class
      RETURNING VALUE(r_message_number) TYPE symsgno.

ENDCLASS.



CLASS ycl_aai_fc_message_class_tools IMPLEMENTATION.

  METHOD create.

    CLEAR r_response.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->create(
      EXPORTING
        iv_name              = CONV #( l_message_class )
        iv_description       = CONV #( i_description )
        iv_package           = l_package
        iv_transport_request = l_transport_request
    ).

    IF l_success = abap_false.
      r_response = |An error occurred while creating the message class { l_message_class }.|.
      RETURN.
    ENDIF.

    r_response = |Message class { l_message_class } created successfully.|.

  ENDMETHOD.

  METHOD add_message.

    DATA l_msgnr TYPE symsgno.

    DATA lt_message TYPE if_adt_mc_res_controller=>tt_message_api.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

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
        AND obj_name = @l_message_class
      INTO @DATA(ls_tadir).

    l_msgnr = i_message_number.

    IF l_msgnr IS INITIAL.
      l_msgnr = me->_get_next_number( l_message_class ).
    ENDIF.

    lt_message = VALUE #( ( message_no = l_msgnr
                            text = i_message_text ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = l_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_true
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    DATA(l_success) = lo_message_class_api->update_message(
                        iv_name              = CONV #( l_message_class )
                        it_message           = lt_message
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while adding the message { l_msgnr }.|.
      RETURN.
    ENDIF.

    r_response = |Message { l_msgnr } added successfully.|.

  ENDMETHOD.

  METHOD update_message.

    DATA lt_message TYPE if_adt_mc_res_controller=>tt_message_api.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

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
        AND obj_name = @l_message_class
      INTO @DATA(ls_tadir).

    lt_message = VALUE #( ( message_no = i_message_number text = i_message_text ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->update_message(
                        iv_name              = CONV #( l_message_class )
                        it_message           = lt_message
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while updating the message { i_message_number }.|.
      RETURN.
    ENDIF.

    r_response = |Message { i_message_number } updated successfully.|.

  ENDMETHOD.

  METHOD delete_message.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

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
        AND obj_name = @l_message_class
      INTO @DATA(ls_tadir).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->delete(
                        iv_name              = CONV #( l_message_class )
                        iv_number            = i_message_number
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while deleting the message { i_message_number }.|.
      RETURN.
    ENDIF.

    r_response = |Message { i_message_number } deleted successfully.|.

  ENDMETHOD.

  METHOD read_all_messages.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = l_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_true
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    IF lt_messages IS INITIAL.
      r_response = |The message class { l_message_class } has no messages.|.
      RETURN.
    ENDIF.

    r_response = |The message class { l_message_class } has the following messages:|.

    LOOP AT lt_messages ASSIGNING FIELD-SYMBOL(<ls_message>).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - '{ <ls_message>-msgnr }' { <ls_message>-text }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD _get_next_number.

    DATA l_msgnr TYPE symsgno.

    r_message_number = 0.

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = i_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_true
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    l_msgnr = 1.

    DO 999 TIMES.

      READ TABLE lt_messages TRANSPORTING NO FIELDS
        WITH KEY msgnr = l_msgnr.

      IF sy-subrc <> 0.
        r_message_number = l_msgnr.
        EXIT.
      ENDIF.

      l_msgnr = l_msgnr + 1.

    ENDDO.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read_all_messages) = abap_false.
    DATA(l_add_message) = abap_false.
    DATA(l_delete_message) = abap_true.
    DATA(l_get_next) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
          EXPORTING
            i_message_class     = 'ZMSG002'
            i_description       = 'Testing ADT API'
            i_package           = 'Z001'
            i_transport_request = 'NPLK900132'
        ).

      WHEN l_add_message.

        l_response = me->add_message(
                       i_message_class     = 'ZMSG002'
*                       i_message_number    = '003'
                       i_message_text      = 'Testing ADT API 2'
                       i_transport_request = 'NPLK900125'
                     ).

      WHEN l_read_all_messages.

        l_response = me->read_all_messages( i_message_class = 'ZMSG001' ).

      WHEN l_delete_message.

        l_response = me->delete_message(
                       i_message_class     = 'ZMSG002'
                       i_message_number    = '002'
                       i_transport_request = 'NPLK900125'
                     ).

      WHEN l_get_next.

        DATA(l_msgno) = me->_get_next_number( 'ZMSG001' ).

        l_response = l_msgno.

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
