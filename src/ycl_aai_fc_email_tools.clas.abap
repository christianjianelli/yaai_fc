CLASS ycl_aai_fc_email_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS send_mail
      IMPORTING
                i_recipient       TYPE yde_aai_fc_email_recipient
                i_cc              TYPE yde_aai_fc_email_cc OPTIONAL
                i_subject         TYPE yde_aai_fc_email_subject
                i_body            TYPE yde_aai_fc_email_body
                i_type            TYPE yde_aai_fc_email_type DEFAULT 'HTM'
                i_t_attachments   TYPE ytt_aai_fc_file_attachments OPTIONAL
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_email_tools IMPLEMENTATION.

  METHOD send_mail.

    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          lo_recipient    TYPE REF TO if_recipient_bcs.

    DATA: lt_receivers    TYPE STANDARD TABLE OF adr6-smtp_addr.

    DATA: l_subject     TYPE so_obj_des,
          lt_body       TYPE STANDARD TABLE OF soli,
          l_sent_to_all TYPE abap_bool.

    CLEAR r_response.

    TRY.

        l_subject = i_subject.

        lt_body = cl_bcs_convert=>string_to_soli( iv_string = i_body ).

        lo_send_request = cl_bcs=>create_persistent( ).

        lo_document = cl_document_bcs=>create_document( i_type = i_type
                                                        i_text = lt_body
                                                        i_subject = l_subject ).

        lo_send_request->set_document( lo_document ).

        lo_recipient = cl_cam_address_bcs=>create_internet_address( CONV #( i_recipient ) ).

        lo_send_request->add_recipient( lo_recipient ).

        l_sent_to_all = lo_send_request->send( ).

        COMMIT WORK.

        IF l_sent_to_all = abap_true.
          r_response = |Email sent successfully to { i_recipient }, subject: { i_subject }|.
        ELSE.
          r_response = |Email sending failed for { i_recipient }, subject: { i_subject }|.
        ENDIF.

      CATCH cx_bcs INTO DATA(lx_bcs).

        r_response = |Error sending email for { i_recipient }, subject: { i_subject }, error: { lx_bcs->get_text( ) }|.

    ENDTRY.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

  ENDMETHOD.

ENDCLASS.
