CLASS ycl_aai_fc_abap_activate DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS get_allowed_object_types
      RETURNING VALUE(r_response) TYPE string.

    METHODS mass_activation_transp_request
      IMPORTING
                i_transport_request TYPE trkorr
      RETURNING VALUE(r_response)   TYPE string.

    METHODS mass_activation
      IMPORTING
                i_t_objects       TYPE ytt_aai_fc_object_activation
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS _is_allowed
      IMPORTING
                i_object_type       TYPE trobjtype
      RETURNING VALUE(r_is_allowed) TYPE abap_bool.

    METHODS _is_ddic
      IMPORTING
                i_object_type    TYPE trobjtype
      RETURNING VALUE(r_is_ddic) TYPE abap_bool.

ENDCLASS.



CLASS ycl_aai_fc_abap_activate IMPLEMENTATION.

  METHOD mass_activation_transp_request.

    DATA: lo_checklist TYPE REF TO cl_wb_checklist,
          lt_objects   TYPE STANDARD TABLE OF dwinactiv,
          ls_object    TYPE dwinactiv,
          l_no_force   TYPE boole_d.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    lo_cts_api->read(
      EXPORTING
        i_transport_request = l_transport_request
      IMPORTING
        e_s_header          = DATA(ls_header)
        e_t_objects         = DATA(lt_transport_request_objects)
    ).

    LOOP AT lt_transport_request_objects ASSIGNING FIELD-SYMBOL(<ls_transport_request_object>).

      " DDIC objects
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      IF me->_is_ddic( i_object_type = <ls_transport_request_object>-object ).

        SELECT SINGLE @abap_true
          FROM tadir
          WHERE object = @<ls_transport_request_object>-object
            AND obj_name = @<ls_transport_request_object>-obj_name
            AND delflag <> @abap_true
           INTO @DATA(l_exists).

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        APPEND VALUE #( object = <ls_transport_request_object>-object
                        obj_name = <ls_transport_request_object>-obj_name ) TO lt_objects.

      ENDIF.

    ENDLOOP.

    IF lt_objects IS NOT INITIAL.

      " DDIC objects activation
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
        EXPORTING
          suppress_enqueue       = abap_true
          suppress_corr_insert   = abap_true
          activate_ddic_objects  = abap_true
          ui_decoupled           = abap_true
        IMPORTING
          p_no_force_activation  = l_no_force
          p_checklist            = lo_checklist
        TABLES
          objects                = lt_objects
        EXCEPTIONS
          excecution_error       = 1
          cancelled              = 2
          insert_into_corr_error = 3
          OTHERS                 = 4.

      IF sy-subrc <> 0 AND lo_checklist IS NOT BOUND.
        " Handle activation error
        r_response = |Error(s) while activating DDIC objects.|.
        RETURN.
      ENDIF.

      lo_checklist->get_error_messages(
        IMPORTING
          p_error_tab = DATA(lt_errors)                 " Error Message Table
      ).

      READ TABLE lt_errors TRANSPORTING NO FIELDS
        WITH KEY mtype = 'E'.

      IF sy-subrc = 0.
        DATA(l_mtype) = 'E'.
      ELSE.

        READ TABLE lt_errors TRANSPORTING NO FIELDS
          WITH KEY mtype = 'W'.

        IF sy-subrc = 0.
          l_mtype = 'W'.
        ENDIF.

      ENDIF.

      LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<ls_error>).

        IF sy-tabix = 1.
          IF l_mtype = 'W'.
            r_response = |Warning(s) occurred while activating the DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ELSE.
            r_response = |Error(s) occurred while activating the DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ENDIF.
        ENDIF.

        IF <ls_error>-edit_req IS BOUND.

          r_response = |{ r_response }Object: { <ls_error>-edit_req->object_name }{ cl_abap_char_utilities=>newline }|.

          IF <ls_error>-edit_req->object_state IS BOUND.
            r_response = |{ r_response }{ <ls_error>-edit_req->object_state->get_description( ) }{ cl_abap_char_utilities=>newline }|.
          ENDIF.

        ENDIF.

        IF <ls_error>-message-msgid IS NOT INITIAL AND
           <ls_error>-message-msgty IS NOT INITIAL AND
           <ls_error>-message-msgno IS NOT INITIAL.

          MESSAGE ID <ls_error>-message-msgid
            TYPE <ls_error>-message-msgty
            NUMBER <ls_error>-message-msgno
            WITH <ls_error>-message-msgv1
                 <ls_error>-message-msgv2
                 <ls_error>-message-msgv3
                 <ls_error>-message-msgv4
            INTO DATA(l_message).

          r_response = |{ r_response }{ l_message }{ cl_abap_char_utilities=>newline }|.

        ELSE.

          LOOP AT <ls_error>-mtext ASSIGNING FIELD-SYMBOL(<l_mtext>).
            r_response = |{ r_response }{ <l_mtext> }{ cl_abap_char_utilities=>newline }|.
          ENDLOOP.

        ENDIF.

      ENDLOOP.

      IF lt_errors IS NOT INITIAL.
        RETURN.
      ENDIF.

    ENDIF.

    FREE lt_objects.

    " Non-DDIC objects
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT lt_transport_request_objects ASSIGNING <ls_transport_request_object>.

      IF NOT me->_is_ddic( i_object_type = <ls_transport_request_object>-object ).

        SELECT SINGLE @abap_true
          FROM tadir
          WHERE object = @<ls_transport_request_object>-object
            AND obj_name = @<ls_transport_request_object>-obj_name
            AND delflag <> @abap_true
           INTO @l_exists.

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        APPEND VALUE #( object = <ls_transport_request_object>-object
                        obj_name = <ls_transport_request_object>-obj_name ) TO lt_objects.

      ENDIF.

    ENDLOOP.

    IF lt_objects IS NOT INITIAL.

      CLEAR lo_checklist.

      " Non-DDIC objects activation
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
        EXPORTING
          suppress_enqueue       = abap_true
          suppress_corr_insert   = abap_true
          activate_ddic_objects  = abap_false
          ui_decoupled           = abap_true
        IMPORTING
          p_no_force_activation  = l_no_force
          p_checklist            = lo_checklist
        TABLES
          objects                = lt_objects
        EXCEPTIONS
          excecution_error       = 1
          cancelled              = 2
          insert_into_corr_error = 3
          OTHERS                 = 4.

      IF sy-subrc <> 0 AND lo_checklist IS NOT BOUND.
        " Handle activation error
        r_response = |Error(s) while activating Non-DDIC objects.|.
        RETURN.
      ENDIF.

      lo_checklist->get_error_messages(
        IMPORTING
          p_error_tab = lt_errors               " Error Message Table
      ).

      CLEAR l_mtype.

      READ TABLE lt_errors TRANSPORTING NO FIELDS
        WITH KEY mtype = 'E'.

      IF sy-subrc = 0.
        l_mtype = 'E'.
      ELSE.

        READ TABLE lt_errors TRANSPORTING NO FIELDS
          WITH KEY mtype = 'W'.

        IF sy-subrc = 0.
          l_mtype = 'W'.
        ENDIF.

      ENDIF.

      LOOP AT lt_errors ASSIGNING <ls_error>.

        IF sy-tabix = 1.
          IF l_mtype = 'W'.
            r_response = |Warning(s) occurred while activating the Non-DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ELSE.
            r_response = |Error(s) occurred while activating the Non-DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ENDIF.
        ENDIF.

        IF <ls_error>-edit_req IS BOUND.

          r_response = |{ r_response }Object: { <ls_error>-edit_req->object_name }{ cl_abap_char_utilities=>newline }|.

          IF <ls_error>-edit_req->object_state IS BOUND.
            r_response = |{ r_response }{ <ls_error>-edit_req->object_state->get_description( ) }{ cl_abap_char_utilities=>newline }|.
          ENDIF.

        ENDIF.

        IF <ls_error>-message-msgid IS NOT INITIAL AND
           <ls_error>-message-msgty IS NOT INITIAL AND
           <ls_error>-message-msgno IS NOT INITIAL.

          MESSAGE ID <ls_error>-message-msgid
            TYPE <ls_error>-message-msgty
            NUMBER <ls_error>-message-msgno
            WITH <ls_error>-message-msgv1
                 <ls_error>-message-msgv2
                 <ls_error>-message-msgv3
                 <ls_error>-message-msgv4
            INTO l_message.

          r_response = |{ r_response }{ l_message }{ cl_abap_char_utilities=>newline }|.

        ELSE.

          LOOP AT <ls_error>-mtext ASSIGNING <l_mtext>.
            r_response = |{ r_response }{ <l_mtext> }{ cl_abap_char_utilities=>newline }|.
          ENDLOOP.

        ENDIF.

      ENDLOOP.

      IF lt_errors IS NOT INITIAL.
        RETURN.
      ENDIF.

    ENDIF.

    r_response = |Transport request { i_transport_request } objects activated successfully.|.

  ENDMETHOD.

  METHOD mass_activation.

    DATA: lo_checklist TYPE REF TO cl_wb_checklist,
          lt_objects   TYPE STANDARD TABLE OF dwinactiv,
          ls_object    TYPE dwinactiv,
          l_no_force   TYPE boole_d.

    DATA(l_has_errors) = abap_false.

    " DDIC objects
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT i_t_objects ASSIGNING FIELD-SYMBOL(<ls_object>).

      IF me->_is_ddic( i_object_type = <ls_object>-object ).

        APPEND VALUE #( object = <ls_object>-object
                        obj_name = <ls_object>-obj_name ) TO lt_objects.

      ENDIF.

    ENDLOOP.

    IF lt_objects IS NOT INITIAL.

      " DDIC objects activation
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
        EXPORTING
          suppress_enqueue       = abap_true
          suppress_corr_insert   = abap_true
          activate_ddic_objects  = abap_true
          ui_decoupled           = abap_true
        IMPORTING
          p_no_force_activation  = l_no_force
          p_checklist            = lo_checklist
        TABLES
          objects                = lt_objects
        EXCEPTIONS
          excecution_error       = 1
          cancelled              = 2
          insert_into_corr_error = 3
          OTHERS                 = 4.

      IF sy-subrc <> 0 AND lo_checklist IS NOT BOUND.
        " Handle activation error
        r_response = |Error(s) while activating the DDIC objects.|.
        RETURN.
      ENDIF.

      lo_checklist->get_error_messages(
        IMPORTING
          p_error_tab = DATA(lt_errors)                 " Error Message Table
      ).

      READ TABLE lt_errors TRANSPORTING NO FIELDS
        WITH KEY mtype = 'E'.

      IF sy-subrc = 0.
        DATA(l_mtype) = 'E'.
      ELSE.

        READ TABLE lt_errors TRANSPORTING NO FIELDS
          WITH KEY mtype = 'W'.

        IF sy-subrc = 0.
          l_mtype = 'W'.
        ENDIF.

      ENDIF.

      LOOP AT lt_errors ASSIGNING FIELD-SYMBOL(<ls_error>).

        IF sy-tabix = 1.
          IF l_mtype = 'W'.
            r_response = |Warning(s) occurred while activating the DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ELSE.
            r_response = |Error(s) occurred while activating the DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ENDIF.
        ENDIF.

        IF <ls_error>-edit_req IS BOUND.

          r_response = |{ r_response }Object: { <ls_error>-edit_req->object_name }{ cl_abap_char_utilities=>newline }|.

          IF <ls_error>-edit_req->object_state IS BOUND.
            r_response = |{ r_response }{ <ls_error>-edit_req->object_state->get_description( ) }{ cl_abap_char_utilities=>newline }|.
          ENDIF.

        ENDIF.

        IF <ls_error>-message-msgid IS NOT INITIAL AND
           <ls_error>-message-msgty IS NOT INITIAL AND
           <ls_error>-message-msgno IS NOT INITIAL.

          MESSAGE ID <ls_error>-message-msgid
            TYPE <ls_error>-message-msgty
            NUMBER <ls_error>-message-msgno
            WITH <ls_error>-message-msgv1
                 <ls_error>-message-msgv2
                 <ls_error>-message-msgv3
                 <ls_error>-message-msgv4
            INTO DATA(l_message).

          r_response = |{ r_response }{ l_message }{ cl_abap_char_utilities=>newline }|.

        ELSE.

          LOOP AT <ls_error>-mtext ASSIGNING FIELD-SYMBOL(<l_mtext>).
            r_response = |{ r_response }{ <l_mtext> }{ cl_abap_char_utilities=>newline }|.
          ENDLOOP.

        ENDIF.

      ENDLOOP.

      IF lt_errors IS NOT INITIAL.
        RETURN.
      ENDIF.

    ENDIF.

    FREE lt_objects.

    " Non-DDIC objects
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    LOOP AT i_t_objects ASSIGNING <ls_object>.

      IF NOT me->_is_ddic( i_object_type = <ls_object>-object ).

        APPEND VALUE #( object = <ls_object>-object
                        obj_name = <ls_object>-obj_name ) TO lt_objects.

      ENDIF.

    ENDLOOP.

    IF lt_objects IS NOT INITIAL.

      CLEAR lo_checklist.

      " Non-DDIC objects activation
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
        EXPORTING
          suppress_enqueue       = abap_true
          suppress_corr_insert   = abap_true
          activate_ddic_objects  = abap_false
          ui_decoupled           = abap_true
        IMPORTING
          p_no_force_activation  = l_no_force
          p_checklist            = lo_checklist
        TABLES
          objects                = lt_objects
        EXCEPTIONS
          excecution_error       = 1
          cancelled              = 2
          insert_into_corr_error = 3
          OTHERS                 = 4.

      IF sy-subrc <> 0.
        " Handle activation error
        r_response = |Error while activating the Non-DDIC objects.|.
        RETURN.
      ENDIF.

      lo_checklist->get_error_messages(
        IMPORTING
          p_error_tab = lt_errors               " Error Message Table
      ).

      READ TABLE lt_errors TRANSPORTING NO FIELDS
        WITH KEY mtype = 'E'.

      IF sy-subrc = 0.
        l_mtype = 'E'.
      ELSE.

        READ TABLE lt_errors TRANSPORTING NO FIELDS
          WITH KEY mtype = 'W'.

        IF sy-subrc = 0.
          l_mtype = 'W'.
        ENDIF.

      ENDIF.

      LOOP AT lt_errors ASSIGNING <ls_error>.

        IF sy-tabix = 1.
          IF l_mtype = 'W'.
            r_response = |Warning(s) occurred while activating the Non-DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ELSE.
            r_response = |Error(s) occurred while activating the Non-DDIC objects.{ cl_abap_char_utilities=>newline }|.
          ENDIF.
        ENDIF.

        IF <ls_error>-edit_req IS BOUND.

          r_response = |{ r_response }Object: { <ls_error>-edit_req->object_name }{ cl_abap_char_utilities=>newline }|.

          IF <ls_error>-edit_req->object_state IS BOUND.
            r_response = |{ r_response }{ <ls_error>-edit_req->object_state->get_description( ) }{ cl_abap_char_utilities=>newline }|.
          ENDIF.

        ENDIF.

        IF <ls_error>-message-msgid IS NOT INITIAL AND
           <ls_error>-message-msgty IS NOT INITIAL AND
           <ls_error>-message-msgno IS NOT INITIAL.

          MESSAGE ID <ls_error>-message-msgid
            TYPE <ls_error>-message-msgty
            NUMBER <ls_error>-message-msgno
            WITH <ls_error>-message-msgv1
                 <ls_error>-message-msgv2
                 <ls_error>-message-msgv3
                 <ls_error>-message-msgv4
            INTO l_message.

          r_response = |{ r_response }{ l_message }{ cl_abap_char_utilities=>newline }|.

        ELSE.

          LOOP AT <ls_error>-mtext ASSIGNING <l_mtext>.
            r_response = |{ r_response }{ <l_mtext> }{ cl_abap_char_utilities=>newline }|.
          ENDLOOP.

        ENDIF.

      ENDLOOP.

      IF lt_errors IS NOT INITIAL.
        RETURN.
      ENDIF.

    ENDIF.

    r_response = |Objects activated successfully.|.

  ENDMETHOD.

  METHOD get_allowed_object_types.

    r_response = |Here is the list of the allowed ABAP object types for mass activation:|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Domain: { ycl_aai_fc_domain_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Data Eelement: { ycl_aai_fc_data_element_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Structure: { ycl_aai_fc_structure_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Table: { ycl_aai_fc_table_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Table Type: { ycl_aai_fc_table_type_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - CDS View: { ycl_aai_fc_cds_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Class: { ycl_aai_fc_oo_class_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Interface: { ycl_aai_fc_oo_interface_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Function Group: { ycl_aai_fc_func_group_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Function Module: { ycl_aai_fc_func_module_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Program: { ycl_aai_fc_program_tools=>mc_object }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Include: { ycl_aai_fc_include_tools=>mc_object }|.

  ENDMETHOD.

  METHOD _is_allowed.

    r_is_allowed = COND #( WHEN i_object_type = ycl_aai_fc_domain_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_data_element_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_structure_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_table_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_table_type_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_cds_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_oo_class_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_oo_interface_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_func_group_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_func_module_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_program_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_include_tools=>mc_object
                           THEN abap_true
                           ELSE abap_false ).

  ENDMETHOD.

  METHOD _is_ddic.

    r_is_ddic = COND #( WHEN i_object_type = ycl_aai_fc_domain_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_data_element_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_structure_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_table_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_table_type_tools=>mc_object OR
                                i_object_type = ycl_aai_fc_cds_tools=>mc_object
                           THEN abap_true
                           ELSE abap_false ).

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_mass_activate) = abap_false.
    DATA(l_transp_request_activate) = abap_true.
    DATA(l_allowed_object_types) = abap_false.

    CASE abap_true.

      WHEN l_allowed_object_types.

        l_response = me->get_allowed_object_types( ).

      WHEN l_mass_activate.

        l_response = me->mass_activation( i_t_objects = VALUE #( ( object = 'DOMA' obj_name = 'ZDO_TEST_DDIF_DOMA_PUT' )
                                                                 ( object = 'DDLS' obj_name = 'ZI_TEST_XYZ' )
                                                                 ( object = 'PROG' obj_name = 'ZTESTTOOL1' ) ) ).

      WHEN l_transp_request_activate.

        l_response = me->mass_activation_transp_request( i_transport_request = 'NPLK900125' ).

    ENDCASE.

    IF l_response IS NOT INITIAL.
      out->write( l_response ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
