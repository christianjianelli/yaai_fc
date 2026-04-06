CLASS ycl_aai_ddic_structure_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid    TYPE e071-pgmid  VALUE 'R3TR',
               mc_object   TYPE e071-object VALUE 'TABL',
               mc_tabclass TYPE tabclass    VALUE 'INTTAB'.

    METHODS create
      IMPORTING
                i_structure_name    TYPE yde_aai_fc_structure
                i_short_description TYPE as4text
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
                i_t_components      TYPE ytt_aai_fc_struct_fields
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_structure_name  TYPE yde_aai_fc_structure
      RETURNING VALUE(r_response) TYPE string.

    METHODS update
      IMPORTING
                i_structure_name    TYPE yde_aai_fc_structure
                i_short_description TYPE as4text OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_components      TYPE ytt_aai_fc_struct_fields OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_structure_name    TYPE yde_aai_fc_structure
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_structure_name    TYPE yde_aai_fc_structure OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS activate
      IMPORTING
                i_structure_name  TYPE yde_aai_fc_structure
      RETURNING VALUE(r_response) TYPE string.

    METHODS exists
      IMPORTING
                i_structure_name TYPE yde_aai_fc_structure
      RETURNING VALUE(r_exists)  TYPE abap_bool.

    METHODS is_locked
      IMPORTING
                i_structure_name TYPE yde_aai_fc_structure
      RETURNING VALUE(r_locked)  TYPE abap_bool.

    METHODS is_active
      IMPORTING
                i_structure_name TYPE yde_aai_fc_structure
      RETURNING VALUE(r_active)  TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_ddic_structure_tools IMPLEMENTATION.

  METHOD create.

    DATA lt_structure_fields TYPE STANDARD TABLE OF dd03p.

    DATA ls_structure TYPE dd02v.

    DATA l_rc TYPE i.

    DATA(l_structure_name) = i_structure_name.

    l_structure_name = condense( to_upper( l_structure_name ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    DATA(lo_aai_fc_ddic_tools) = NEW ycl_aai_fc_ddic_tools_util( ).

    ls_structure-tabname = l_structure_name.
    ls_structure-tabclass = mc_tabclass.
    ls_structure-ddtext = i_short_description.
    ls_structure-ddlanguage = sy-langu.

    LOOP AT i_t_components ASSIGNING FIELD-SYMBOL(<ls_component>).

      DATA(l_position) = sy-tabix.

      APPEND INITIAL LINE TO lt_structure_fields ASSIGNING FIELD-SYMBOL(<ls_structure_field>).

      <ls_structure_field>-tabname = l_structure_name.
      <ls_structure_field>-fieldname = <ls_component>-field_name.
      <ls_structure_field>-position = l_position.
      <ls_structure_field>-ddlanguage = sy-langu.
      <ls_structure_field>-ddtext = <ls_component>-short_description.
      <ls_structure_field>-rollname = <ls_component>-data_element.

      IF <ls_component>-data_type IS NOT INITIAL.

        lo_aai_fc_ddic_tools->determine_data_type(
          EXPORTING
            i_data_type = <ls_component>-data_type
          IMPORTING
            e_data_type = DATA(l_data_type)
            e_error     = DATA(l_error)
        ).

        IF l_error IS INITIAL.
          <ls_structure_field>-datatype = l_data_type.
        ENDIF.

      ENDIF.

      <ls_structure_field>-leng = <ls_component>-length.
      <ls_structure_field>-decimals = <ls_component>-decimals.

      IF <ls_component>-ref_field IS NOT INITIAL.
        <ls_structure_field>-reftable = l_structure_name.
        <ls_structure_field>-reffield = condense( to_upper( <ls_component>-ref_field ) ).
      ENDIF.

    ENDLOOP.

    CALL FUNCTION 'DDIF_TABL_PUT'
      EXPORTING
        name              = ls_structure-tabname
        dd02v_wa          = ls_structure
      TABLES
        dd03p_tab         = lt_structure_fields
      EXCEPTIONS
        tabl_not_found    = 1
        name_inconsistent = 2
        tabl_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.

      r_response = |An error occurred while creating the structure { l_structure_name }.|.

      RETURN.
    ENDIF.

    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus                  = ' '
        wi_tadir_pgmid                 = mc_pgmid
        wi_tadir_object                = mc_object
        wi_tadir_obj_name              = CONV sobj_name( l_structure_name )
        wi_tadir_author                = sy-uname
        wi_tadir_devclass              = l_package
        wi_set_genflag                 = abap_false
      EXCEPTIONS
        tadir_entry_not_existing       = 1
        tadir_entry_ill_type           = 2
        no_systemname                  = 3
        no_systemtype                  = 4
        original_system_conflict       = 5
        object_reserved_for_devclass   = 6
        object_exists_global           = 7
        object_exists_local            = 8
        object_is_distributed          = 9
        obj_specification_not_unique   = 10
        no_authorization_to_delete     = 11
        devclass_not_existing          = 12
        simultanious_set_remove_repair = 13
        order_missing                  = 14
        no_modification_of_head_syst   = 15
        pgmid_object_not_allowed       = 16
        masterlanguage_not_specified   = 17
        devclass_not_specified         = 18
        specify_owner_unique           = 19
        loc_priv_objs_no_repair        = 20
        gtadir_not_reached             = 21
        object_locked_for_order        = 22
        change_of_class_not_allowed    = 23
        no_change_from_sap_to_tmp      = 24
        OTHERS                         = 25.

    IF sy-subrc <> 0.

      r_response = |An error occurred while creating the TADIR entry for the newly created structure { l_structure_name }.|.

      RETURN.

    ENDIF.

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name        = ls_structure-tabname
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.

      r_response = |An error occurred while activating the structure { l_structure_name }. { cl_abap_char_utilities=>newline }|.

      DATA(l_inactive) = abap_true.

    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_structure_name )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.

      r_response = |{ r_response }Structure { l_structure_name } created but it was not possible to add it to the transport request { l_transport_request }.|.

      RETURN.

    ENDIF.

    IF l_inactive = abap_false.
      r_response = |Structure { l_structure_name } created successfully.|.
    ELSE.
      r_response = |{ r_response }Structure { l_structure_name } created but not activated.|.
    ENDIF.

  ENDMETHOD.

  METHOD read.

    DATA lt_structure_fields TYPE STANDARD TABLE OF dd03p.

    DATA ls_structure TYPE dd02v.

    DATA l_state TYPE ddobjstate.

    DATA(l_structure_name) = i_structure_name.

    l_structure_name = condense( to_upper( l_structure_name ) ).

    SELECT tabname, as4local, as4vers
      FROM dd02l
      WHERE tabname = @l_structure_name
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_dd02l).

    IF sy-subrc <> 0.
      r_response = |Structure { l_structure_name } not found.|.
      RETURN.
    ENDIF.

    READ TABLE lt_dd02l INTO DATA(ls_dd01l)
      WITH KEY as4vers = 'A'.

    IF sy-subrc = 0.
      l_state = 'A'.
    ELSE.
      l_state = 'M'.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_structure_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name          = l_structure_name
        state         = l_state
        langu         = ls_tadir-masterlang
      IMPORTING
        gotstate      = l_state
        dd02v_wa      = ls_structure
      TABLES
        dd03p_tab     = lt_structure_fields
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc <> 0 OR ls_structure IS INITIAL.
      r_response = |Structure { l_structure_name } not found.|.
      RETURN.
    ENDIF.

    r_response = |Structure: { l_structure_name }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_structure-ddtext }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Package: { ls_tadir-devclass }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Fields:|.

    LOOP AT lt_structure_fields ASSIGNING FIELD-SYMBOL(<ls_structure_field>).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Field: { <ls_structure_field>-fieldname }|.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Description: { <ls_structure_field>-ddtext }|.

      IF <ls_structure_field>-rollname IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Data Element: { <ls_structure_field>-rollname }|.
      ENDIF.

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Type: { <ls_structure_field>-datatype }|.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Length: { <ls_structure_field>-leng ALPHA = OUT }|.

      IF <ls_structure_field>-datatype = 'DEC' OR <ls_structure_field>-datatype = 'QUAN' OR <ls_structure_field>-datatype = 'CURR'.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Decimals: { <ls_structure_field>-decimals ALPHA = OUT }|.
      ENDIF.

      IF <ls_structure_field>-reffield IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Reference Table: { <ls_structure_field>-reftable }|.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Reference Field: { <ls_structure_field>-reffield }|.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD search.

    DATA: l_structure         TYPE string,
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
      RETURN.
    ENDIF.

    l_structure = |*{ i_structure_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_structure IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_structure.
          CONTINUE.
        ENDIF.

      ENDIF.

      SELECT SINGLE tabname, ddlanguage, ddtext
        FROM dd02v
        WHERE tabname = @<ls_tadir>-obj_name
          AND ddlanguage = @<ls_tadir>-masterlang
        INTO @DATA(ls_dd01v).

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_dd01v-ddtext CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }Structure: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_dd01v-ddtext }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    DATA lt_structure_fields TYPE STANDARD TABLE OF dd03p.

    DATA ls_structure TYPE dd02v.

    DATA: l_state TYPE ddobjstate VALUE 'A',
          l_rc    TYPE i.

    DATA(l_structure_name) = i_structure_name.

    l_structure_name = condense( to_upper( l_structure_name ) ).

    IF me->exists( l_structure_name ) = abap_false.
      r_response = |Structure { l_structure_name } not found.|.
      RETURN.
    ENDIF.

    IF me->is_locked( l_structure_name ) = abap_true.
      r_response = |Structure { l_structure_name } is locked.|.
      RETURN.
    ENDIF.

    IF me->is_active( l_structure_name ) = abap_false.
      l_state = 'M'.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_structure_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name          = l_structure_name
        state         = l_state
        langu         = ls_tadir-masterlang
      IMPORTING
        dd02v_wa      = ls_structure
      TABLES
        dd03p_tab     = lt_structure_fields
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Structure { l_structure_name } not found.|.
      RETURN.
    ENDIF.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    IF i_short_description IS NOT INITIAL.
      ls_structure-ddtext = i_short_description.
    ENDIF.

    IF i_t_components IS NOT INITIAL.

      FREE lt_structure_fields.

      DATA(lo_aai_fc_ddic_tools) = NEW ycl_aai_fc_ddic_tools_util( ).

    ENDIF.

    LOOP AT i_t_components ASSIGNING FIELD-SYMBOL(<ls_component>).

      DATA(l_position) = sy-tabix.

      APPEND INITIAL LINE TO lt_structure_fields ASSIGNING FIELD-SYMBOL(<ls_structure_field>).

      <ls_structure_field>-tabname = l_structure_name.
      <ls_structure_field>-fieldname = <ls_component>-field_name.
      <ls_structure_field>-position = l_position.
      <ls_structure_field>-ddlanguage = sy-langu.
      <ls_structure_field>-ddtext = <ls_component>-short_description.
      <ls_structure_field>-rollname = <ls_component>-data_element.

      IF <ls_component>-data_type IS NOT INITIAL.

        lo_aai_fc_ddic_tools->determine_data_type(
          EXPORTING
            i_data_type = <ls_component>-data_type
          IMPORTING
            e_data_type = DATA(l_data_type)
            e_error     = DATA(l_error)
        ).

        IF l_error IS INITIAL.
          <ls_structure_field>-datatype = l_data_type.
        ENDIF.

      ENDIF.

      <ls_structure_field>-leng = <ls_component>-length.
      <ls_structure_field>-decimals = <ls_component>-decimals.

      IF <ls_component>-ref_field IS NOT INITIAL.
        <ls_structure_field>-reftable = l_structure_name.
        <ls_structure_field>-reffield = condense( to_upper( <ls_component>-ref_field ) ).
      ENDIF.

    ENDLOOP.

    CALL FUNCTION 'DDIF_TABL_PUT'
      EXPORTING
        name              = ls_structure-tabname
        dd02v_wa          = ls_structure
      TABLES
        dd03p_tab         = lt_structure_fields
      EXCEPTIONS
        tabl_not_found    = 1
        name_inconsistent = 2
        tabl_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.

      r_response = |An error occurred while updating the structure { l_structure_name }.|.

      RETURN.
    ENDIF.

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name        = ls_structure-tabname
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.

      r_response = |An error occurred while activating the structure { l_structure_name }. { cl_abap_char_utilities=>newline }|.

      DATA(l_inactive) = abap_true.

    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_structure_name )
        i_object_class = 'DICT'
        i_package = ls_tadir-devclass
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.

      r_response = |{ r_response }Structure { l_structure_name } updated but it was not possible to add it to the transport request { l_transport_request }.|.

      RETURN.

    ENDIF.

    IF l_inactive = abap_false.
      r_response = |Structure { l_structure_name } updated successfully.|.
    ELSE.
      r_response = |{ r_response }Structure { l_structure_name } updated but not activated.|.
    ENDIF.

  ENDMETHOD.

  METHOD delete.

  ENDMETHOD.

  METHOD activate.

    DATA l_rc TYPE i.

    CLEAR r_response.

    DATA(l_structure_name) = i_structure_name.

    l_structure_name = condense( to_upper( l_structure_name ) ).

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name        = l_structure_name
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.
      r_response = |An error occurred while activating the structure { l_structure_name }.'|.
      RETURN.
    ENDIF.

    r_response = |Structure { l_structure_name } activated successfully.|.

  ENDMETHOD.

  METHOD exists.

    SELECT SINGLE @abap_true
      FROM dd02l
      INTO @r_exists
      WHERE tabname = @i_structure_name.

  ENDMETHOD.

  METHOD is_active.

    SELECT SINGLE @abap_true
      FROM dd02l
      INTO @r_active
      WHERE tabname = @i_structure_name
        AND as4local = 'A'.

  ENDMETHOD.

  METHOD is_locked.

    DATA: lt_lock_entries TYPE STANDARD TABLE OF seqg3.

    DATA: l_argument TYPE seqg3-garg.

    r_locked = abap_false.

    l_argument = |{ mc_object }{ i_structure_name }|.

    CALL FUNCTION 'ENQUEUE_READ'
      EXPORTING
        guname                = '*'
        garg                  = l_argument
      TABLES
        enq                   = lt_lock_entries
      EXCEPTIONS
        communication_failure = 0
        system_failure        = 0
        OTHERS                = 0.

    READ TABLE lt_lock_entries
      TRANSPORTING NO FIELDS
      WITH KEY gobj = 'ESDICT'.

    IF sy-subrc = 0.
      r_locked = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_update) = abap_true.


    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
                       i_structure_name    = 'ZST_TEST_DDIF_TABL_PUT1'
                       i_short_description = 'Test Structure Create tool'
                       i_transport_request = 'NPLK900132'
                       i_package           = 'Z001'
                       i_t_components      = VALUE #( ( field_name = 'FIELD1' data_type = 'CHAR' length = '10' )
                                                      ( field_name = 'FIELD2' data_type = 'STRING' )
                                                      ( field_name = 'VAL' data_type = 'CURR' length = '13' decimals = '2' ref_field = 'CURRENCY' )
                                                      ( field_name = 'CURRENCY' data_element = 'WAERS' ) )
                     ).

      WHEN l_read.

        l_response = me->read( 'ZST_TEST_DDIF_TABL_PUT1' ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = 'YAAI_FC'
*                       i_structure_name    =
*                       i_short_description =
                     ).

      WHEN l_update.

        l_response = me->update(
                       i_structure_name    = 'ZST_TEST_DDIF_TABL_PUT1'
                       i_short_description = 'Test Structure Create tool'
                       i_transport_request = 'NPLK900132'
                       i_t_components      = VALUE #( ( field_name = 'DOCID' data_type = 'CHAR' length = '10' )
                                                      ( field_name = 'TOTAMT' data_type = 'CURR' length = '13' decimals = '2' ref_field = 'CURCY' )
                                                      ( field_name = 'CURCY' data_element = 'WAERS' ) )
                     ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
