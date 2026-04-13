CLASS ycl_aai_fc_data_element_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'DTEL'.

    METHODS create
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_short_description TYPE as4text
                i_domain_name       TYPE yde_aai_fc_domain OPTIONAL
                i_data_type         TYPE yde_aai_fc_data_type OPTIONAL
                i_length            TYPE yde_aai_fc_length OPTIONAL
                i_decimals          TYPE yde_aai_fc_decimals OPTIONAL
                i_label_short       TYPE scrtext_s
                i_label_medium      TYPE scrtext_m
                i_label_long        TYPE scrtext_l
                i_label_heading     TYPE reptext
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_response)   TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_data_element_name TYPE yde_aai_fc_data_element OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_short_description TYPE as4text OPTIONAL
                i_domain_name       TYPE yde_aai_fc_domain
                i_data_type         TYPE yde_aai_fc_data_type
                i_length            TYPE yde_aai_fc_length
                i_decimals          TYPE yde_aai_fc_decimals OPTIONAL
                i_label_short       TYPE scrtext_s OPTIONAL
                i_label_medium      TYPE scrtext_m OPTIONAL
                i_label_long        TYPE scrtext_l OPTIONAL
                i_label_heading     TYPE reptext OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS activate
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_response)   TYPE string.

    METHODS set_translation
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_transport_request TYPE yde_aai_fc_transport_request
                i_language          TYPE spras
                i_short_description TYPE as4text
                i_label_short       TYPE scrtext_s
                i_label_medium      TYPE scrtext_m
                i_label_long        TYPE scrtext_l
                i_label_heading     TYPE reptext
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_translation
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_language          TYPE spras
      RETURNING VALUE(r_response)   TYPE string.

    METHODS exists
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_exists)     TYPE abap_bool.

    METHODS is_locked
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_locked)     TYPE abap_bool.

    METHODS is_active
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_active)     TYPE abap_bool.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_fc_data_element_tools IMPLEMENTATION.

  METHOD create.

    DATA ls_data_element TYPE dd04v.

    DATA l_rc TYPE i.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    IF i_data_type IS NOT INITIAL.

      NEW ycl_aai_fc_ddic_tools_util( )->determine_data_type(
        EXPORTING
          i_data_type = i_data_type
        IMPORTING
          e_data_type = DATA(l_data_type)
          e_error     = DATA(l_error)
      ).

      IF l_data_type IS INITIAL.

        r_response = l_error.

        RETURN.

      ENDIF.

    ENDIF.

    ls_data_element-rollname = l_data_element.
    ls_data_element-ddlanguage = sy-langu.
    ls_data_element-domname = condense( to_upper( i_domain_name ) ).
    ls_data_element-ddtext = i_short_description.
    ls_data_element-reptext = i_label_heading.
    ls_data_element-scrtext_s = i_label_short.
    ls_data_element-scrtext_m = i_label_medium.
    ls_data_element-scrtext_l = i_label_long.
    ls_data_element-as4user = sy-uname.
    ls_data_element-as4date = sy-datum.
    ls_data_element-as4time = sy-uzeit.
    ls_data_element-dtelmaster = sy-langu.
    ls_data_element-datatype = l_data_type.
    ls_data_element-leng = i_length.
    ls_data_element-decimals = i_decimals.
    ls_data_element-outputlen = i_length.
    ls_data_element-headlen = 55.
    ls_data_element-scrlen1 = 10.
    ls_data_element-scrlen2 = 20.
    ls_data_element-scrlen3 = 40.

    CALL FUNCTION 'DDIF_DTEL_PUT'
      EXPORTING
        name              = l_data_element
        dd04v_wa          = ls_data_element
      EXCEPTIONS
        dtel_not_found    = 1
        name_inconsistent = 2
        dtel_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.
      r_response = |An error occurred while creating the Data Element { l_data_element }.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus                  = ' '
        wi_tadir_pgmid                 = mc_pgmid
        wi_tadir_object                = mc_object
        wi_tadir_obj_name              = CONV sobj_name( l_data_element )
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
      r_response = 'An error occurred while creating the TADIR entry for the newly created Data Element'.
      RETURN.
    ENDIF.

    CALL FUNCTION 'DDIF_DTEL_ACTIVATE'
      EXPORTING
        name        = l_data_element
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.
      r_response = |An error occurred while activating the Data Element { l_data_element }.'|.
      DATA(l_inactive) = abap_true.
    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_data_element )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.
      r_response = |{ r_response }Data Element { l_data_element } created but it was not possible to add it to the transport request { l_transport_request }.|.
      RETURN.
    ENDIF.

    IF l_inactive = abap_false.
      r_response = |Data Element { l_data_element } created successfully.|.
    ELSE.
      r_response = |{ r_response }Data Element { l_data_element } created but not activated.|.
    ENDIF.

  ENDMETHOD.

  METHOD read.

    DATA ls_data_element TYPE dd04v.

    DATA l_state TYPE ddobjstate.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    SELECT rollname, as4local
      FROM dd04l
      INTO TABLE @DATA(lt_dd01l)
      WHERE rollname = @l_data_element.

    IF sy-subrc <> 0.
      r_response = |Data Element { l_data_element } not found.|.
      RETURN.
    ENDIF.

    IF me->is_active( l_data_element ) = abap_true.
      l_state = 'A'.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_data_element
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_DTEL_GET'
      EXPORTING
        name          = l_data_element
        state         = l_state
        langu         = ls_tadir-masterlang
      IMPORTING
        gotstate      = l_state
        dd04v_wa      = ls_data_element
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Error while reading Data Element { l_data_element }.|.
      RETURN.
    ENDIF.

    r_response = |Data Element Name: { l_data_element }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Description: { ls_data_element-ddtext }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Label short: { ls_data_element-scrtext_s }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Label medium: { ls_data_element-scrtext_m }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Label long: { ls_data_element-scrtext_l }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Label heading: { ls_data_element-reptext }|.

    IF ls_data_element-domname IS NOT INITIAL.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Domain Name: { ls_data_element-domname }|.
    ENDIF.

    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Type: { ls_data_element-datatype }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Length: { ls_data_element-leng ALPHA = OUT }|.

    IF ls_data_element-datatype = 'DEC' OR ls_data_element-datatype = 'QUAN' OR ls_data_element-datatype = 'CURR'.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Decimals: { ls_data_element-decimals ALPHA = OUT }|.
    ENDIF.

  ENDMETHOD.

  METHOD search.

    DATA: l_data_element_name TYPE string,
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
      r_response = |No data element found.|.
      RETURN.
    ENDIF.

    l_data_element_name = |*{ i_data_element_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF i_data_element_name IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_data_element_name.
          CONTINUE.
        ENDIF.

      ENDIF.

      SELECT SINGLE rollname, domname, ddlanguage, datatype, leng, decimals, ddtext
        FROM dd04v
        WHERE rollname = @<ls_tadir>-obj_name
          AND ddlanguage = @<ls_tadir>-masterlang
        INTO @DATA(ls_dd04v).

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_dd04v-ddtext CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }Data Element: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_dd04v-ddtext }{ cl_abap_char_utilities=>newline }|.

      IF ls_dd04v-domname IS NOT INITIAL.
        r_response = |{ r_response }Domain: { ls_dd04v-domname }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }Type: { ls_dd04v-datatype }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Length: { ls_dd04v-leng ALPHA = OUT }|.

      IF ls_dd04v-datatype = 'DEC' OR ls_dd04v-datatype = 'QUAN' OR ls_dd04v-datatype = 'CURR'.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Decimals: { ls_dd04v-decimals ALPHA = OUT }|.
      ENDIF.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |No data element found.|.
    ENDIF.

  ENDMETHOD.

  METHOD update.

    DATA ls_data_element TYPE dd04v.

    DATA l_state TYPE ddobjstate VALUE 'A'.

    DATA l_rc TYPE i.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    SELECT as4local, as4vers
      FROM dd04l
      INTO TABLE @DATA(lt_dd01l)
      WHERE rollname = @l_data_element.

    IF sy-subrc <> 0.
      r_response = |Data Element { l_data_element } not found.|.
      RETURN.
    ENDIF.

    IF me->is_active( l_data_element ) = abap_false.
      l_state = 'M'.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_data_element
      INTO @DATA(ls_tadir).

    IF i_data_type IS NOT INITIAL.

      NEW ycl_aai_fc_ddic_tools_util( )->determine_data_type(
        EXPORTING
          i_data_type = i_data_type
        IMPORTING
          e_data_type = DATA(l_data_type)
          e_error     = DATA(l_error)
      ).

      IF l_data_type IS INITIAL.
        r_response = l_error.
        RETURN.
      ENDIF.

    ENDIF.

    CALL FUNCTION 'DDIF_DTEL_GET'
      EXPORTING
        name          = l_data_element
        state         = l_state
        langu         = ls_tadir-masterlang
      IMPORTING
        gotstate      = l_state
        dd04v_wa      = ls_data_element
      EXCEPTIONS
        illegal_input = 1
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Error while reading Data Element { l_data_element }.|.
      RETURN.
    ENDIF.

    ls_data_element-rollname = l_data_element.

    ls_data_element-domname = condense( to_upper( i_domain_name ) ).

    IF i_short_description IS NOT INITIAL.
      ls_data_element-ddtext = i_short_description.
    ENDIF.

    IF i_label_heading IS NOT INITIAL.
      ls_data_element-reptext = i_label_heading.
    ENDIF.

    IF i_label_short IS NOT INITIAL.
      ls_data_element-scrtext_s = i_label_short.
    ENDIF.

    IF i_label_medium IS NOT INITIAL.
      ls_data_element-scrtext_m = i_label_medium.
    ENDIF.

    IF i_label_long IS NOT INITIAL.
      ls_data_element-scrtext_l = i_label_long.
    ENDIF.

    ls_data_element-datatype = l_data_type.
    ls_data_element-leng = i_length.
    ls_data_element-outputlen = i_length.

    IF i_short_description IS NOT INITIAL.
      ls_data_element-decimals = i_decimals.
    ENDIF.

    CALL FUNCTION 'DDIF_DTEL_PUT'
      EXPORTING
        name              = l_data_element
        dd04v_wa          = ls_data_element
      EXCEPTIONS
        dtel_not_found    = 1
        name_inconsistent = 2
        dtel_inconsistent = 3
        put_failure       = 4
        put_refused       = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.
      r_response = |An error occurred while creating the Data Element { l_data_element }.|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'DDIF_DTEL_ACTIVATE'
      EXPORTING
        name        = l_data_element
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.
      r_response = |An error occurred while activating the Data Element { l_data_element }.{ cl_abap_char_utilities=>newline }|.
      DATA(l_inactive) = abap_true.
    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_data_element )
        i_object_class = 'DICT'
        i_package = ls_tadir-devclass
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.
      r_response = |{ r_response }Data Element { l_data_element } updated but it was not possible to add it to the transport request { l_transport_request }.|.
      RETURN.
    ENDIF.

    IF l_inactive = abap_false.
      r_response = |{ r_response }Data Element { l_data_element } updated successfully.|.
    ELSE.
      r_response = |{ r_response }Data Element { l_data_element } updated but not activated.|.
    ENDIF.

  ENDMETHOD.

  METHOD delete.

    DATA lt_objects_with_references TYPE STANDARD TABLE OF dcobjbez.

    DATA l_deleted TYPE abap_bool.

    CLEAR r_response.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    SELECT rollname, as4local
      FROM dd04l
      INTO TABLE @DATA(lt_dd01l)
      WHERE rollname = @l_data_element.

    IF sy-subrc <> 0.
      r_response = |Data Element { l_data_element } not found.|.
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
        AND obj_name = @l_data_element
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_OBJECT_DELETE'
      EXPORTING
        type                    = mc_object
        name                    = l_data_element
      IMPORTING
        deleted                 = l_deleted
      TABLES
        objects_with_references = lt_objects_with_references
      EXCEPTIONS
        illegal_input           = 1
        no_authority            = 2
        OTHERS                  = 3.

    IF sy-subrc <> 0 OR l_deleted IS INITIAL.

      r_response = |Data Element { l_data_element } was not deleted.|.

      LOOP AT lt_objects_with_references ASSIGNING FIELD-SYMBOL(<ls_objects_with_references>).

        IF sy-tabix = 1.
          r_response = |{ r_response }{ cl_abap_char_utilities=>newline }The Data Element { l_data_element } is still being referenced by the following object(s):|.
        ENDIF.

        r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - Object Name: { <ls_objects_with_references>-name } Type: { <ls_objects_with_references>-type } |.

      ENDLOOP.

      RETURN.
    ENDIF.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_data_element )
        i_object_class = 'DICT'
        i_package = ls_tadir-devclass
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.
      r_response = |{ r_response }Data Element { l_data_element } deleted but it was not possible to add it to the transport request { l_transport_request }.|.
    ENDIF.

    IF r_response IS INITIAL.
      r_response = |Data Element { l_data_element } was deleted successfully.|.
    ELSE.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Data Element { l_data_element } was deleted.|.
    ENDIF.

  ENDMETHOD.

  METHOD get_translation.

    DATA lt_rng_state TYPE RANGE OF ddobjstate.

    CLEAR r_response.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    SELECT as4local, as4vers
      FROM dd04l
      WHERE rollname = @l_data_element
      INTO TABLE @DATA(lt_dd01l).

    IF sy-subrc <> 0.
      r_response = |Data Element { l_data_element } not found.|.
      RETURN.
    ENDIF.

    READ TABLE lt_dd01l INTO DATA(ls_dd01l)
      WITH KEY as4vers = 'A'.

    IF me->is_active( l_data_element ) = abap_true.
      lt_rng_state = VALUE #( ( sign = 'I' option = 'EQ' low = 'A' ) ) .
    ENDIF.

    SELECT rollname, ddlanguage, as4local, as4vers, ddtext, reptext, scrtext_s, scrtext_m, scrtext_l
      FROM dd04t
      WHERE rollname = @l_data_element
        AND ddlanguage = @l_language
        AND as4local IN @lt_rng_state
      INTO @DATA(ls_dd04t)
      UP TO 1 ROWS.
    ENDSELECT.

    IF sy-subrc = 0.

      SELECT SINGLE sptxt
        FROM t002t
        WHERE spras = @sy-langu
          AND sprsl = @l_language
        INTO @DATA(l_language_description).

      r_response = |Data Element: { l_data_element }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Language: { l_language_description }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Short Description: { ls_dd04t-ddtext }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Label Short: { ls_dd04t-scrtext_s }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Label Medium: { ls_dd04t-scrtext_m }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Label Long: { ls_dd04t-scrtext_l }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Label Heading: { ls_dd04t-reptext }{ cl_abap_char_utilities=>newline }|.

    ELSE.

      r_response = |No translation to language `{ l_language }` found for Data Element { l_data_element }.|.

    ENDIF.

  ENDMETHOD.

  METHOD set_translation.

    DATA: lt_pcx_s1 TYPE STANDARD TABLE OF lxe_pcx_s1,
          lt_e071   TYPE trwbo_t_e071.

    DATA: l_custmnr TYPE lxecustmnr VALUE '999999',
          l_objtype TYPE trobjtype VALUE mc_object,
          l_objname TYPE lxeobjname,
          l_status  TYPE lxestatprc,
          l_error   TYPE lxestring.

    CLEAR r_response.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    l_objname = l_data_element.

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_data_element
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Data Element { l_data_element } not found.|.
      RETURN.
    ENDIF.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

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

    lt_pcx_s1 = VALUE #( ( textkey = 'DDTEXT' t_text = i_short_description )
                         ( textkey = 'SCRTEXT_S' t_text = i_label_short )
                         ( textkey = 'SCRTEXT_M' t_text = i_label_medium )
                         ( textkey = 'SCRTEXT_L' t_text = i_label_long )
                         ( textkey = 'REPTEXT' t_text = i_short_description ) ).

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
      r_response = |Error updating translations. Data Element: { l_data_element }. Target language: { l_language }.|.
      RETURN.
    ENDIF.

    lt_e071 = VALUE #( ( trkorr = l_transport_request
                         pgmid = 'LANG'
                         object = 'DTED'
                         obj_name = l_data_element
                         lang = l_language ) ).

    DATA(l_success) = NEW ycl_aai_fc_cts_api( )->add_object(
      EXPORTING
        i_transport_request = l_transport_request
      CHANGING
        ch_t_e071           = lt_e071
    ).

    IF l_success = abap_true.
      r_response = |Translations updated successfully. Data Element: { l_data_element }. Target language: { l_language }.|.
    ELSE.
      r_response = |Translations updated successfully but they were not added to the transport request { l_transport_request }. Data Element: { l_data_element }. Target language: { l_language }.|.
    ENDIF.

  ENDMETHOD.

  METHOD activate.

    DATA l_rc TYPE i.

    CLEAR r_response.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    CALL FUNCTION 'DDIF_DTEL_ACTIVATE'
      EXPORTING
        name        = l_data_element
      IMPORTING
        rc          = l_rc
      EXCEPTIONS
        not_found   = 1
        put_failure = 2
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc > 4.
      r_response = |An error occurred while activating the Data Element { l_data_element }.'|.
      RETURN.
    ENDIF.

    r_response = |Data Element { l_data_element } activated successfully.|.

  ENDMETHOD.

  METHOD exists.

    SELECT SINGLE @abap_true
      FROM dd04l
      INTO @r_exists
      WHERE rollname = @i_data_element_name.

  ENDMETHOD.

  METHOD is_active.

    SELECT SINGLE @abap_true
      FROM dd04l
      INTO @r_active
      WHERE rollname = @i_data_element_name
        AND as4local = 'A'.

  ENDMETHOD.

  METHOD is_locked.

    DATA: lt_lock_entries TYPE STANDARD TABLE OF seqg3.

    DATA: l_argument TYPE seqg3-garg.

    r_locked = abap_false.

    l_argument = |{ mc_object }{ i_data_element_name }|.

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
    DATA(l_delete) = abap_true.
    DATA(l_get_translation) = abap_false.
    DATA(l_set_translation) = abap_false.

    CASE abap_true.

      WHEN l_create.

        me->create(
          EXPORTING
            i_data_element_name = 'ZDE_TEST_DDIF_DTEL_PUT4'
            i_short_description = 'Test DTEL create via DDIF_DTEL_PUT'
*            i_domain_name       =
            i_data_type         = 'CHAR'
            i_length            = 30
*            i_decimals          =
            i_label_short       = 'DTEL_PUT'
            i_label_medium      = 'DDIF_DTEL_PUT'
            i_label_long        = 'Test DTEL create via DDIF_DTEL_PUT'
            i_label_heading     = 'Test DTEL create via DDIF_DTEL_PUT'
            i_transport_request = 'NPLK900132'
            i_package           = 'Z001'
          RECEIVING
            r_response          = l_response
        ).

      WHEN l_read.

        l_response = me->read( i_data_element_name = 'ZDE_AI_USER_QUESTION' ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = 'Z001'
                       i_data_element_name = 'BUS'
*                       i_short_description =
                     ).

      WHEN l_delete.

        l_response = me->delete(
                       i_data_element_name = 'ZDE_TEST_DDIF_DTEL_PUT4'
                       i_transport_request = 'NPLK900132'
                     ).

      WHEN l_get_translation.

        l_response = me->get_translation(
          EXPORTING
            i_data_element_name = 'ZDE_PRICE'
            i_language          = 'D'
        ).

      WHEN l_set_translation.

        l_response = me->set_translation(
                       i_data_element_name = 'ZDE_TEST_DDIF_DTEL_PUT3'
                       i_transport_request = 'NPLK900134'
                       i_language          = 'S'
                       i_short_description = 'Precio del artículo'
                       i_label_short       = 'Precio art'
                       i_label_medium      = 'Precio del artículo'
                       i_label_long        = 'Precio del artículo'
                       i_label_heading     = 'Precio del artículo' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
