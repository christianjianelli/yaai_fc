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

        LOOP AT i_t_attachments ASSIGNING FIELD-SYMBOL(<ls_attachment>).

          DATA(l_file_content_bin) = cl_abap_codepage=>convert_to( source = <ls_attachment>-file_content ).

          lo_document->add_attachment( i_attachment_type    = space
                                       i_attachment_subject = CONV #( <ls_attachment>-filename )
                                       i_att_content_hex    = cl_document_bcs=>xstring_to_solix( l_file_content_bin )
                                       i_attachment_size    = CONV #( xstrlen( l_file_content_bin ) ) ).

        ENDLOOP.

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

    DATA(l_response) = me->send_mail(
                         i_recipient     = '...'
*                         i_cc            =
                         i_subject       = 'Test'
                         i_body          = 'Test'
                         i_type          = 'RAW'
                         i_t_attachments = VALUE #( ( filename = 'doc.md' file_content = '# markdown content' file_type = 'ASC' ) )
                       ).

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
