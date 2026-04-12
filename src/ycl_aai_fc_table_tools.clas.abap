CLASS ycl_aai_fc_table_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid    TYPE e071-pgmid  VALUE 'R3TR',
               mc_object   TYPE e071-object VALUE 'TABL',
               mc_tabclass TYPE tabclass    VALUE 'TRANSP'.

    METHODS create
      IMPORTING
                i_table_name        TYPE yde_aai_fc_database_table
                i_short_description TYPE as4text
                i_delivery_class    TYPE yde_aai_fc_delivery_class OPTIONAL
                i_data_class        TYPE yde_aai_fc_data_class OPTIONAL
                i_size_category     TYPE yde_aai_fc_size_category OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
                i_t_components      TYPE ytt_aai_fc_table_fields
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_table_name      TYPE yde_aai_fc_database_table
      RETURNING VALUE(r_response) TYPE string.

    METHODS update
      IMPORTING
                i_table_name        TYPE yde_aai_fc_database_table
                i_short_description TYPE as4text OPTIONAL
                i_delivery_class    TYPE yde_aai_fc_delivery_class OPTIONAL
                i_data_class        TYPE yde_aai_fc_data_class OPTIONAL
                i_size_category     TYPE yde_aai_fc_size_category OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_components      TYPE ytt_aai_fc_table_fields OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_table_name        TYPE yde_aai_fc_database_table
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_table_name        TYPE yde_aai_fc_database_table OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS activate
      IMPORTING
                i_table_name      TYPE yde_aai_fc_database_table
      RETURNING VALUE(r_response) TYPE string.

    METHODS exists
      IMPORTING
                i_table_name    TYPE yde_aai_fc_database_table
      RETURNING VALUE(r_exists) TYPE abap_bool.

    METHODS is_locked
      IMPORTING
                i_table_name    TYPE yde_aai_fc_database_table
      RETURNING VALUE(r_locked) TYPE abap_bool.

    METHODS is_active
      IMPORTING
                i_table_name    TYPE yde_aai_fc_database_table
      RETURNING VALUE(r_active) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_table_tools IMPLEMENTATION.

  METHOD create.

    DATA lt_table_fields TYPE STANDARD TABLE OF dd03p.

    DATA: ls_table         TYPE dd02v,
          ls_tech_settings TYPE dd09v.

    DATA: l_rc            TYPE i,
          l_size_category TYPE string.

    DATA(l_table_name) = i_table_name.

    l_table_name = condense( to_upper( l_table_name ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    IF to_upper( i_delivery_class ) <> 'A' AND
       to_upper( i_delivery_class ) <> 'C'.

      r_response = |The delivery class { i_delivery_class } is invalid.|.

      RETURN.

    ENDIF.

    l_size_category = condense( i_size_category ).

    FIND REGEX '^[0-9]$' IN l_size_category.

    IF sy-subrc <> 0.

      r_response = |The size category { i_size_category } is invalid.|.

      RETURN.

    ENDIF.

    DATA(l_data_class) = to_upper( i_data_class ).

    IF l_data_class <> 'APPL0' AND
       l_data_class <> 'APPL1' AND
       l_data_class <> 'APPL2'.

      r_response = |The data class { i_data_class } is invalid.|.

      RETURN.

    ENDIF.

    DATA(lo_aai_fc_ddic_tools) = NEW ycl_aai_fc_ddic_tools_util( ).

    ls_table-tabname = l_table_name.
    ls_table-tabclass = mc_tabclass.
    ls_table-ddtext = i_short_description.
    ls_table-ddlanguage = sy-langu.

    " Delivery Class
    ls_table-contflag = COND #( WHEN i_delivery_class IS NOT INITIAL
                                THEN to_upper( i_delivery_class )
                                ELSE 'A' ).

    ls_tech_settings-tabname = l_table_name.

    " Size Category
    ls_tech_settings-tabkat = COND #( WHEN l_size_category IS NOT INITIAL
                                      THEN l_size_category
                                      ELSE '0' ).

    " Data Class
    ls_tech_settings-tabart = COND #( WHEN l_data_class IS NOT INITIAL
                                      THEN l_data_class
                                      ELSE 'APPL1' ).

    LOOP AT i_t_components ASSIGNING FIELD-SYMBOL(<ls_component>).

      DATA(l_position) = sy-tabix.

      APPEND INITIAL LINE TO lt_table_fields ASSIGNING FIELD-SYMBOL(<ls_table_field>).

      <ls_table_field>-tabname = l_table_name.
      <ls_table_field>-fieldname = <ls_component>-field_name.

      IF <ls_component>-key_flag IS NOT INITIAL.
        <ls_table_field>-keyflag = abap_true.
      ENDIF.

      <ls_table_field>-position = l_position.
      <ls_table_field>-ddlanguage = sy-langu.
      <ls_table_field>-ddtext = <ls_component>-short_description.
      <ls_table_field>-rollname = <ls_component>-data_element.

      IF <ls_component>-data_type IS NOT INITIAL.

        lo_aai_fc_ddic_tools->determine_data_type(
          EXPORTING
            i_data_type = <ls_component>-data_type
          IMPORTING
            e_data_type = DATA(l_data_type)
            e_error     = DATA(l_error)
        ).

        IF l_error IS INITIAL.
          <ls_table_field>-datatype = l_data_type.
        ENDIF.

      ENDIF.

      <ls_table_field>-leng = <ls_component>-length.
      <ls_table_field>-decimals = <ls_component>-decimals.

      IF <ls_component>-ref_field IS NOT INITIAL.
        <ls_table_field>-reftable = l_table_name.
        <ls_table_field>-reffield = condense( to_upper( <ls_component>-ref_field ) ).
      ENDIF.

    ENDLOOP.

    CALL FUNCTION 'DDIF_TABL_PUT'
      EXPORTING
        name              = ls_table-tabname
        dd02v_wa          = ls_table
        dd09l_wa          = ls_tech_settings
      TABLES
        dd03p_tab         = lt_table_fields
      EXCEPTIONS
        tabl_not_found    = 1
        name_inconsistent = 2
        tabl_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.
      r_response = |An error occurred while creating the table { l_table_name }.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus                  = ' '
        wi_tadir_pgmid                 = mc_pgmid
        wi_tadir_object                = mc_object
        wi_tadir_obj_name              = CONV sobj_name( l_table_name )
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
      r_response = |An error occurred while creating the TADIR entry for the newly created table { l_table_name }.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name        = ls_table-tabname
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.
      r_response = |An error occurred while activating the table { l_table_name }. { cl_abap_char_utilities=>newline }|.
      DATA(l_inactive) = abap_true.
    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_table_name )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.

      r_response = |{ r_response }Table { l_table_name } created but it was not possible to add it to the transport request { l_transport_request }.|.

      RETURN.

    ENDIF.

    IF l_inactive = abap_false.
      r_response = |Table { l_table_name } created successfully.|.
    ELSE.
      r_response = |{ r_response }Table { l_table_name } created but not activated.|.
    ENDIF.

  ENDMETHOD.

  METHOD read.

    DATA lt_table_fields TYPE STANDARD TABLE OF dd03p.

    DATA: ls_table         TYPE dd02v,
          ls_tech_settings TYPE dd09v.

    DATA l_state TYPE ddobjstate.

    DATA(l_table_name) = i_table_name.

    l_table_name = condense( to_upper( l_table_name ) ).

    SELECT tabname, as4local, as4vers
      FROM dd02l
      WHERE tabname = @l_table_name
        AND tabclass = @mc_tabclass
      ORDER BY PRIMARY KEY
      INTO TABLE @DATA(lt_dd02l).

    IF sy-subrc <> 0.
      r_response = |Table { l_table_name } not found.|.
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
        AND obj_name = @l_table_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name          = l_table_name
        state         = l_state
        langu         = ls_tadir-masterlang
      IMPORTING
        gotstate      = l_state
        dd02v_wa      = ls_table
        dd09l_wa      = ls_tech_settings
      TABLES
        dd03p_tab     = lt_table_fields
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc <> 0 OR ls_table IS INITIAL.
      r_response = |Table { l_table_name } not found.|.
      RETURN.
    ENDIF.

    r_response = |Table: { l_table_name }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_table-ddtext }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Package: { ls_tadir-devclass }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Delivery Class: { ls_table-contflag }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Data Class: { ls_tech_settings-tabart }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Size Category: { ls_tech_settings-tabkat }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Fields:|.

    LOOP AT lt_table_fields ASSIGNING FIELD-SYMBOL(<ls_table_field>).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Field: { <ls_table_field>-fieldname }|.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Description: { <ls_table_field>-ddtext }|.

      IF <ls_table_field>-rollname IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Data Element: { <ls_table_field>-rollname }|.
      ENDIF.

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Type: { <ls_table_field>-datatype }|.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Length: { <ls_table_field>-leng ALPHA = OUT }|.

      IF <ls_table_field>-datatype = 'DEC' OR <ls_table_field>-datatype = 'QUAN' OR <ls_table_field>-datatype = 'CURR'.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Decimals: { <ls_table_field>-decimals ALPHA = OUT }|.
      ENDIF.

      IF <ls_table_field>-reffield IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Reference Table: { <ls_table_field>-reftable }|.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Reference Field: { <ls_table_field>-reffield }|.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD search.

    DATA: l_table             TYPE string,
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

    l_table = |*{ i_table_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_table IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_table.
          CONTINUE.
        ENDIF.

      ENDIF.

      SELECT SINGLE tabname, ddlanguage, ddtext
        FROM dd02v
        WHERE tabname = @<ls_tadir>-obj_name
          AND tabclass = @mc_tabclass
          AND ddlanguage = @<ls_tadir>-masterlang
        INTO @DATA(ls_dd01v).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_dd01v-ddtext CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }Table: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_dd01v-ddtext }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    DATA lt_table_fields TYPE STANDARD TABLE OF dd03p.

    DATA: ls_table         TYPE dd02v,
          ls_tech_settings TYPE dd09v.

    DATA: l_state         TYPE ddobjstate VALUE 'A',
          l_rc            TYPE i,
          l_size_category TYPE string.

    DATA(l_table_name) = i_table_name.

    l_table_name = condense( to_upper( l_table_name ) ).

    IF me->exists( l_table_name ) = abap_false.
      r_response = |Table { l_table_name } not found.|.
      RETURN.
    ENDIF.

    IF me->is_locked( l_table_name ) = abap_true.
      r_response = |Table { l_table_name } is locked.|.
      RETURN.
    ENDIF.

    IF me->is_active( l_table_name ) = abap_false.
      l_state = 'M'.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_table_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        name          = l_table_name
        state         = l_state
        langu         = ls_tadir-masterlang
      IMPORTING
        dd02v_wa      = ls_table
        dd09l_wa      = ls_tech_settings
      TABLES
        dd03p_tab     = lt_table_fields
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Table { l_table_name } not found.|.
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
      ls_table-ddtext = i_short_description.
    ENDIF.

    " Size Category
    IF i_size_category IS NOT INITIAL.

      l_size_category = condense( i_size_category ).

      FIND REGEX '^[0-9]$' IN l_size_category.

      IF sy-subrc <> 0.

        r_response = |The size category { i_size_category } is invalid.|.

        RETURN.

      ENDIF.

      ls_tech_settings-tabkat = l_size_category.

    ENDIF.

    " Data Class
    IF i_data_class IS NOT INITIAL.

      DATA(l_data_class) = to_upper( i_data_class ).

      IF l_data_class <> 'APPL0' AND
         l_data_class <> 'APPL1' AND
         l_data_class <> 'APPL2'.

        r_response = |The data class { i_data_class } is invalid.|.

        RETURN.

      ENDIF.

      ls_tech_settings-tabart = i_data_class.

    ENDIF.

    IF i_t_components IS NOT INITIAL.

      FREE lt_table_fields.

      DATA(lo_aai_fc_ddic_tools) = NEW ycl_aai_fc_ddic_tools_util( ).

    ENDIF.

    LOOP AT i_t_components ASSIGNING FIELD-SYMBOL(<ls_component>).

      DATA(l_position) = sy-tabix.

      APPEND INITIAL LINE TO lt_table_fields ASSIGNING FIELD-SYMBOL(<ls_table_field>).

      <ls_table_field>-tabname = l_table_name.
      <ls_table_field>-fieldname = <ls_component>-field_name.

      IF <ls_component>-key_flag IS NOT INITIAL.
        <ls_table_field>-keyflag = abap_true.
      ENDIF.

      <ls_table_field>-position = l_position.
      <ls_table_field>-ddlanguage = sy-langu.
      <ls_table_field>-ddtext = <ls_component>-short_description.
      <ls_table_field>-rollname = <ls_component>-data_element.

      IF <ls_component>-data_type IS NOT INITIAL.

        lo_aai_fc_ddic_tools->determine_data_type(
          EXPORTING
            i_data_type = <ls_component>-data_type
          IMPORTING
            e_data_type = DATA(l_data_type)
            e_error     = DATA(l_error)
        ).

        IF l_error IS INITIAL.
          <ls_table_field>-datatype = l_data_type.
        ENDIF.

      ENDIF.

      <ls_table_field>-leng = <ls_component>-length.
      <ls_table_field>-decimals = <ls_component>-decimals.

      IF <ls_component>-ref_field IS NOT INITIAL.
        <ls_table_field>-reftable = l_table_name.
        <ls_table_field>-reffield = condense( to_upper( <ls_component>-ref_field ) ).
      ENDIF.

    ENDLOOP.

    CALL FUNCTION 'DDIF_TABL_PUT'
      EXPORTING
        name              = ls_table-tabname
        dd02v_wa          = ls_table
        dd09l_wa          = ls_tech_settings
      TABLES
        dd03p_tab         = lt_table_fields
      EXCEPTIONS
        tabl_not_found    = 1
        name_inconsistent = 2
        tabl_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.

      r_response = |An error occurred while updating the table { l_table_name }.|.

      RETURN.
    ENDIF.

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name        = ls_table-tabname
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.

      r_response = |An error occurred while activating the table { l_table_name }. { cl_abap_char_utilities=>newline }|.

      DATA(l_inactive) = abap_true.

    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_table_name )
        i_object_class = 'DICT'
        i_package = ls_tadir-devclass
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.

      r_response = |{ r_response }Table { l_table_name } updated but it was not possible to add it to the transport request { l_transport_request }.|.

      RETURN.

    ENDIF.

    IF l_inactive = abap_false.
      r_response = |Table { l_table_name } updated successfully.|.
    ELSE.
      r_response = |{ r_response }Table { l_table_name } updated but not activated.|.
    ENDIF.

  ENDMETHOD.

  METHOD delete.

    DATA lt_objects_with_references TYPE STANDARD TABLE OF dcobjbez.

    DATA l_deleted TYPE abap_bool.

    CLEAR r_response.

    DATA(l_table_name) = i_table_name.

    l_table_name = condense( to_upper( l_table_name ) ).

    SELECT tabname, as4local
      FROM dd02l
      INTO TABLE @DATA(lt_dd01l)
      WHERE tabname = @l_table_name.

    IF sy-subrc <> 0.
      r_response = |Table { l_table_name } not found.|.
      RETURN.
    ENDIF.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, masterlang, devclass
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_table_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_OBJECT_DELETE'
      EXPORTING
        type                    = mc_object
        name                    = l_table_name
      IMPORTING
        deleted                 = l_deleted
      TABLES
        objects_with_references = lt_objects_with_references
      EXCEPTIONS
        illegal_input           = 1
        no_authority            = 2
        OTHERS                  = 3.

    IF sy-subrc <> 0 OR l_deleted IS INITIAL.

      r_response = |Table { l_table_name } was not deleted.|.

      LOOP AT lt_objects_with_references ASSIGNING FIELD-SYMBOL(<ls_objects_with_references>).

        IF sy-tabix = 1.
          r_response = |{ r_response }{ cl_abap_char_utilities=>newline }The Table { l_table_name } is still being referenced by the following object(s):|.
        ENDIF.

        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Object Name: { <ls_objects_with_references>-name } Type: { <ls_objects_with_references>-type } |.

      ENDLOOP.

      RETURN.
    ENDIF.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_table_name )
        i_object_class = 'DICT'
        i_package = ls_tadir-devclass
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.
      r_response = |{ r_response }Table { l_table_name } deleted but it was not possible to add it to the transport request { l_transport_request }.|.
    ENDIF.

    IF r_response IS INITIAL.
      r_response = |Table { l_table_name } was deleted successfully.|.
    ELSE.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Table { l_table_name } was deleted.|.
    ENDIF.

  ENDMETHOD.

  METHOD activate.

    DATA l_rc TYPE i.

    CLEAR r_response.

    DATA(l_table_name) = i_table_name.

    l_table_name = condense( to_upper( l_table_name ) ).

    CALL FUNCTION 'DDIF_TABL_ACTIVATE'
      EXPORTING
        name        = l_table_name
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.
      r_response = |An error occurred while activating the table { l_table_name }.'|.
      RETURN.
    ENDIF.

    r_response = |Table { l_table_name } activated successfully.|.

  ENDMETHOD.

  METHOD exists.

    SELECT SINGLE @abap_true
      FROM dd02l
      INTO @r_exists
      WHERE tabname = @i_table_name.

  ENDMETHOD.

  METHOD is_active.

    SELECT SINGLE @abap_true
      FROM dd02l
      INTO @r_active
      WHERE tabname = @i_table_name
        AND as4local = 'A'.

  ENDMETHOD.

  METHOD is_locked.

    DATA: lt_lock_entries TYPE STANDARD TABLE OF seqg3.

    DATA: l_argument TYPE seqg3-garg.

    r_locked = abap_false.

    l_argument = |{ mc_object }{ i_table_name }|.

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

    DATA(l_create) = abap_true.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_update) = abap_false.
    DATA(l_delete) = abap_false.


    CASE abap_true.

      WHEN l_create.

        l_response = me->create( i_table_name = 'ZTBTEST2'
                                 i_short_description = 'Test Table Create tool 2'
                                 i_transport_request = 'NPLK900133'
                                 i_package = 'Z001'
                                 i_delivery_class = 'A'
                                 i_data_class = 'APPL0'
                                 i_size_category = '1'
                                 i_t_components = VALUE #( ( field_name = 'MANDT' key_flag = 'X' data_element = 'MANDT' )
                                                           ( field_name = 'FIELD1' key_flag = 'X' data_type = 'CHAR' length = '10' )
                                                           ( field_name = 'FIELD2' data_type = 'STRING' )
                                                           ( field_name = 'VAL' data_type = 'CURR' length = '13' decimals = '2' ref_field = 'CURRENCY' )
                                                           ( field_name = 'CURRENCY' data_element = 'WAERS' ) ) ).

      WHEN l_read.

        l_response = me->read( 'ZTBTEST1' ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = 'YAAI'
*                       i_table_name    =
*                       i_short_description =
                     ).

      WHEN l_update.

        l_response = me->update( i_table_name = 'ZTBTEST1'
                                 i_short_description = 'Test Table Update tool'
                                 i_data_class = 'APPL0'
                                 i_size_category = '1'
                                 i_transport_request = 'NPLK900133'
                                 i_t_components = VALUE #( ( field_name = 'MANDT' key_flag = 'X' data_element = 'MANDT' )
                                                           ( field_name = 'FIELD1' key_flag = 'X' data_type = 'CHAR' length = '10' )
                                                           ( field_name = 'TOTAMT' data_type = 'CURR' length = '13' decimals = '2' ref_field = 'CURCY' )
                                                           ( field_name = 'CURCY' data_element = 'WAERS' ) ) ).
      WHEN l_delete.

        l_response = me->delete(
                       i_table_name        = 'ZTBTEST1'
                       i_transport_request = 'NPLK900132'
                     ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
