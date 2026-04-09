CLASS ycl_aai_fc_message_class_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

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
                i_message_number    TYPE symsgno
                i_message_text      TYPE natxt
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

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

    lt_message = VALUE #( ( message_no = i_message_number text = i_message_text ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->update_message(
                        iv_name              = CONV #( l_message_class )
                        it_message           = lt_message
                        iv_transport_request = l_transport_request
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while adding the message { i_message_number }.|.
      RETURN.
    ENDIF.

    r_response = |Message { i_message_number } added successfully.|.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_add_message) = abap_true.

    DATA(l_add_object) = abap_true.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
          EXPORTING
            i_message_class     = 'ZMSG001'
            i_description       = 'Testing ADT API'
            i_package           = 'Z001'
            i_transport_request = 'NPLK900137'
        ).

      WHEN l_add_message.

        l_response = me->add_message(
                       i_message_class     = 'ZMSG001'
                       i_message_number    = '001'
                       i_message_text      = 'Testing ADT API'
                       i_transport_request = 'NPLK900137'
                     ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
