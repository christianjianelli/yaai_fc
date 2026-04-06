CLASS ycl_aai_fc_domain_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'DOMA'.

    METHODS create
      IMPORTING
                i_domain_name       TYPE yde_aai_fc_domain
                i_short_description TYPE as4text
                i_data_type         TYPE yde_aai_fc_data_type
                i_length            TYPE yde_aai_fc_length OPTIONAL
                i_decimals          TYPE yde_aai_fc_decimals OPTIONAL
                i_case_sensitive    TYPE yde_aai_fc_case_sensitive OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
                i_t_fixed_values    TYPE ytt_aai_fc_domain_fixed_val OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_domain_name     TYPE yde_aai_fc_domain
      RETURNING VALUE(r_response) TYPE string.

    METHODS update
      IMPORTING
                i_domain_name       TYPE yde_aai_fc_domain
                i_short_description TYPE as4text OPTIONAL
                i_data_type         TYPE yde_aai_fc_data_type
                i_length            TYPE yde_aai_fc_length OPTIONAL
                i_decimals          TYPE yde_aai_fc_decimals OPTIONAL
                i_case_sensitive    TYPE yde_aai_fc_case_sensitive OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_fixed_values    TYPE ytt_aai_fc_domain_fixed_val
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_domain_name       TYPE yde_aai_fc_domain
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_domain_name       TYPE yde_aai_fc_domain OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS activate
      IMPORTING
                i_domain_name     TYPE yde_aai_fc_domain
      RETURNING VALUE(r_response) TYPE string.

    METHODS set_translation
      IMPORTING
                i_domain_name       TYPE yde_aai_fc_domain
                i_transport_request TYPE yde_aai_fc_transport_request
                i_language          TYPE spras
                i_short_description TYPE as4text
                i_t_fixed_values    TYPE ytt_aai_fc_domain_fixed_val
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_translation
      IMPORTING
                i_domain_name     TYPE yde_aai_fc_domain
                i_language        TYPE spras
      RETURNING VALUE(r_response) TYPE string.

    METHODS exists
      IMPORTING
                i_domain_name   TYPE yde_aai_fc_domain
      RETURNING VALUE(r_exists) TYPE abap_bool.

    METHODS is_locked
      IMPORTING
                i_domain_name   TYPE yde_aai_fc_domain
      RETURNING VALUE(r_locked) TYPE abap_bool.

    METHODS is_active
      IMPORTING
                i_domain_name   TYPE yde_aai_fc_domain
      RETURNING VALUE(r_active) TYPE abap_bool.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_fc_domain_tools IMPLEMENTATION.

  METHOD create.

    DATA lt_fixed_values TYPE STANDARD TABLE OF dd07v.

    DATA ls_domain TYPE dd01v.

    DATA l_rc TYPE i.

    DATA(l_domain_name) = i_domain_name.

    l_domain_name = condense( to_upper( l_domain_name ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

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

    ls_domain-domname = l_domain_name.
    ls_domain-ddlanguage = sy-langu.
    ls_domain-domname = condense( to_upper( i_domain_name ) ).
    ls_domain-ddtext = i_short_description.
    ls_domain-as4user = sy-uname.
    ls_domain-as4date = sy-datum.
    ls_domain-as4time = sy-uzeit.
    ls_domain-datatype = l_data_type.
    ls_domain-leng = i_length.
    ls_domain-decimals = i_decimals.
    ls_domain-lowercase = i_case_sensitive.

    LOOP AT i_t_fixed_values ASSIGNING FIELD-SYMBOL(<ls_fixed_value>).

      APPEND VALUE #( domname = l_domain_name
                      valpos = sy-tabix
                      ddlanguage = sy-langu
                      domvalue_l = <ls_fixed_value>-value
                      domvalue_h = ''
                      ddtext = <ls_fixed_value>-description ) TO lt_fixed_values.

    ENDLOOP.

    CALL FUNCTION 'DDIF_DOMA_PUT'
      EXPORTING
        name              = l_domain_name    " Name of the Domain to be Written
        dd01v_wa          = ls_domain        " Header of the Domain
      TABLES
        dd07v_tab         = lt_fixed_values  " Fixed Values
      EXCEPTIONS
        doma_not_found    = 1                " Header of the Domain could not be Found
        name_inconsistent = 2                " Name in Sources Inconsistent with NAME
        doma_inconsistent = 3                " Inconsistent Sources
        put_failure       = 4                " Write Error (ROLLBACK Recommended)
        put_refused       = 5                " Write not Allowed
        OTHERS            = 6.

    IF sy-subrc <> 0.

      r_response = |An error occurred while creating the domain { l_domain_name }.|.

      RETURN.

    ENDIF.

    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus                  = ' '
        wi_tadir_pgmid                 = mc_pgmid
        wi_tadir_object                = mc_object
        wi_tadir_obj_name              = CONV sobj_name( l_domain_name )
        wi_tadir_author                = sy-uname
        wi_tadir_devclass              = l_package
        wi_set_genflag                 = abap_false
      EXCEPTIONS
        tadir_entry_not_existing       = 1                " Object directory entry does not exist
        tadir_entry_ill_type           = 2                " Transferred TADIR key not compatible with E071
        no_systemname                  = 3                " System name not found
        no_systemtype                  = 4                " System type not defined
        original_system_conflict       = 5                " Object already exists in another system
        object_reserved_for_devclass   = 6                " Object reserved for name range
        object_exists_global           = 7                " Object exists globally
        object_exists_local            = 8                " Object exists locally
        object_is_distributed          = 9                " Object is distributed
        obj_specification_not_unique   = 10               " Object specification for import is not sufficient
        no_authorization_to_delete     = 11               " No permission to delete
        devclass_not_existing          = 12               " Package unknown
        simultanious_set_remove_repair = 13               " Repair flag set/reset simultaneously
        order_missing                  = 14               " Repair request was not transferred
        no_modification_of_head_syst   = 15               " Modification of HEAD-SYST entry not allowed
        pgmid_object_not_allowed       = 16               " PGMID entry not permitted
        masterlanguage_not_specified   = 17               " Master language not specified
        devclass_not_specified         = 18               " Package not specified
        specify_owner_unique           = 19
        loc_priv_objs_no_repair        = 20               " No repair to local-private objects
        gtadir_not_reached             = 21               " The GTADIR cannot be accessed
        object_locked_for_order        = 22
        change_of_class_not_allowed    = 23
        no_change_from_sap_to_tmp      = 24               " Do not switch SAP objects to customer development class
        OTHERS                         = 25.

    IF sy-subrc <> 0.

      r_response = |An error occurred while creating the TADIR entry for the newly created domain { l_domain_name }.|.

      RETURN.

    ENDIF.

    CALL FUNCTION 'DDIF_DOMA_ACTIVATE'
      EXPORTING
        name        = l_domain_name    " Name of the Data Element to be Activated
      EXCEPTIONS
        not_found   = 1                " Data Element not Found
        put_failure = 2                " Data Element could not be Written
        OTHERS      = 3.

    IF sy-subrc <> 0.

      r_response = |An error occurred while activating the domain { l_domain_name }. { cl_abap_char_utilities=>newline }|.

      DATA(l_inactive) = abap_true.

    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_domain_name )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.

      r_response = |{ r_response }Domain { l_domain_name } created but it was not possible to add it to the transport request { l_transport_request }.|.

      RETURN.

    ENDIF.

    IF l_inactive = abap_false.
      r_response = |Domain { l_domain_name } created successfully.|.
    ELSE.
      r_response = |{ r_response }Domain { l_domain_name } created.|.
    ENDIF.

  ENDMETHOD.

  METHOD read.

    DATA lt_fixed_values TYPE STANDARD TABLE OF dd07v.

    DATA ls_domain TYPE dd01v.

    DATA l_state TYPE ddobjstate.

    DATA(l_domain_name) = i_domain_name.

    l_domain_name = condense( to_upper( l_domain_name ) ).

    SELECT as4local, as4vers
      FROM dd01l
      INTO TABLE @DATA(lt_dd01l)
      WHERE domname = @l_domain_name.

    IF sy-subrc <> 0.
      r_response = |Domain { l_domain_name } doesn't exist.|.
      RETURN.
    ENDIF.

    READ TABLE lt_dd01l INTO DATA(ls_dd01l)
      WITH KEY as4vers = 'A'.

    IF me->is_active( l_domain_name ) = abap_true.
      l_state = 'A'.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_domain_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_DOMA_GET'
      EXPORTING
        name          = l_domain_name           " Name of the Domain to be Read
        state         = l_state                 " Read Status of the Domain
        langu         = ls_tadir-masterlang     " Language in which Texts are Read
      IMPORTING
        gotstate      = l_state                 " Status in which Reading took Place
        dd01v_wa      = ls_domain               " Header of the Domain
      TABLES
        dd07v_tab     = lt_fixed_values         " Fixed Domain Values
      EXCEPTIONS
        illegal_input = 1                       " Value not Allowed for Parameter
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Error while reading domain { l_domain_name }.|.
      RETURN.
    ENDIF.

    r_response = |Domain: { l_domain_name }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Description: { ls_domain-ddtext }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Type: { ls_domain-datatype }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Length: { ls_domain-leng ALPHA = OUT }|.

    IF ls_domain-datatype = 'DEC' OR ls_domain-datatype = 'QUAN' OR ls_domain-datatype = 'CURR'.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Decimals: { ls_domain-decimals ALPHA = OUT }|.
    ENDIF.

    IF l_state <> 'A'.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }WARNING: the domain is not active.|.
    ENDIF.

    IF lt_fixed_values IS NOT INITIAL.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Fixed values:|.
    ENDIF.

    LOOP AT lt_fixed_values ASSIGNING FIELD-SYMBOL(<ls_fixed_values>).
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Value:{ <ls_fixed_values>-domvalue_l } Text:{ <ls_fixed_values>-ddtext }|.
    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    DATA lt_fixed_values TYPE STANDARD TABLE OF dd07v.

    DATA ls_domain TYPE dd01v.

    DATA l_state TYPE ddobjstate VALUE 'A'.

    CLEAR r_response.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.

      r_response = |The transport request { l_transport_request } is invalid.|.

      RETURN.

    ENDIF.

    DATA(l_domain_name) = i_domain_name.

    l_domain_name = condense( to_upper( l_domain_name ) ).

    IF me->exists( l_domain_name ) = abap_false.
      r_response = |Domain { l_domain_name } doesn't exist.|.
      RETURN.
    ENDIF.

    IF me->is_locked( l_domain_name ) = abap_true.
      r_response = |Domain { l_domain_name } is locked.|.
      RETURN.
    ENDIF.

    IF me->is_active( l_domain_name ) = abap_false.
      l_state = 'M'.
      RETURN.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, masterlang, devclass
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_domain_name
      INTO @DATA(ls_tadir).

    CALL FUNCTION 'DDIF_DOMA_GET'
      EXPORTING
        name          = l_domain_name           " Name of the Domain to be Read
        state         = l_state                 " Read Status of the Domain
        langu         = ls_tadir-masterlang     " Language in which Texts are Read
      IMPORTING
        gotstate      = l_state                 " Status in which Reading took Place
        dd01v_wa      = ls_domain               " Header of the Domain
      TABLES
        dd07v_tab     = lt_fixed_values         " Fixed Domain Values
      EXCEPTIONS
        illegal_input = 1                       " Value not Allowed for Parameter
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Error while reading domain { l_domain_name }.|.
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

    IF i_short_description IS NOT INITIAL.
      ls_domain-ddtext = i_short_description.
    ENDIF.

    IF l_data_type IS NOT INITIAL.
      ls_domain-datatype = l_data_type.
    ENDIF.

    IF i_length IS NOT INITIAL.
      ls_domain-leng = i_length.
      ls_domain-outputlen = i_length.
    ENDIF.

    IF i_decimals IS NOT INITIAL.
      ls_domain-decimals = i_decimals.
    ENDIF.

    ls_domain-lowercase = i_case_sensitive.

    IF i_t_fixed_values IS NOT INITIAL.

      FREE lt_fixed_values.

      LOOP AT i_t_fixed_values ASSIGNING FIELD-SYMBOL(<ls_fixed_value>).

        APPEND VALUE #( domname = l_domain_name
                        valpos = sy-tabix
                        ddlanguage = ls_tadir-masterlang
                        domvalue_l = <ls_fixed_value>-value
                        domvalue_h = ''
                        ddtext = <ls_fixed_value>-description ) TO lt_fixed_values.

      ENDLOOP.

    ENDIF.

    CALL FUNCTION 'DDIF_DOMA_PUT'
      EXPORTING
        name              = l_domain_name    " Name of the Domain to be Written
        dd01v_wa          = ls_domain        " Header of the Domain
      TABLES
        dd07v_tab         = lt_fixed_values  " Fixed Values
      EXCEPTIONS
        doma_not_found    = 1                " Header of the Domain could not be Found
        name_inconsistent = 2                " Name in Sources Inconsistent with NAME
        doma_inconsistent = 3                " Inconsistent Sources
        put_failure       = 4                " Write Error (ROLLBACK Recommended)
        put_refused       = 5                " Write not Allowed
        OTHERS            = 6.

    IF sy-subrc <> 0.

      r_response = |An error occurred while creating the domain { l_domain_name }.|.

      RETURN.

    ENDIF.

    CALL FUNCTION 'DDIF_DOMA_ACTIVATE'
      EXPORTING
        name        = l_domain_name    " Name of the Data Element to be Activated
      EXCEPTIONS
        not_found   = 1                " Data Element not Found
        put_failure = 2                " Data Element could not be Written
        OTHERS      = 3.

    IF sy-subrc <> 0.

      r_response = |An error occurred while activating the domain { l_domain_name }.{ cl_abap_char_utilities=>newline }|.

      DATA(l_inactive) = abap_true.

    ENDIF.

    COMMIT WORK.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_domain_name )
        i_object_class = 'DICT'
        i_package = ls_tadir-devclass
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.

      r_response = |{ r_response }Domain { l_domain_name } updated but it was not possible to add it to the transport request { l_transport_request }.|.

      RETURN.

    ENDIF.

    IF l_inactive = abap_false.

      r_response = |Domain { l_domain_name } updated successfully.|.

    ELSE.

      r_response = |{ r_response }Domain { l_domain_name } updated but it was not activated..|.

    ENDIF.

  ENDMETHOD.

  METHOD delete.
    "TODO
  ENDMETHOD.

  METHOD activate.

    CLEAR r_response.

    DATA(l_domain) = i_domain_name.

    l_domain = condense( to_upper( l_domain ) ).

    CALL FUNCTION 'DDIF_DOMA_ACTIVATE'
      EXPORTING
        name        = l_domain            " Name of the Data Element to be Activated
      EXCEPTIONS
        not_found   = 1                         " Data Element not Found
        put_failure = 2                         " Data Element could not be Written
        OTHERS      = 3.

    IF sy-subrc <> 0.
      r_response = |An error occurred while activating the domain { l_domain }.'|.
      RETURN.
    ENDIF.

    r_response = |Domain { l_domain } activated successfully.|.

  ENDMETHOD.

  METHOD search.

    DATA: l_domain_name       TYPE string,
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

    l_domain_name = |*{ i_domain_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF i_domain_name IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_domain_name.
          CONTINUE.
        ENDIF.

      ENDIF.

      SELECT SINGLE domname, ddlanguage, datatype, leng, decimals, ddtext
        FROM dd01v
        WHERE domname = @<ls_tadir>-obj_name
          AND ddlanguage = @<ls_tadir>-masterlang
        INTO @DATA(ls_dd01v).

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_dd01v-ddtext CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }Domain: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_dd01v-ddtext }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Type: { ls_dd01v-datatype }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Length: { ls_dd01v-leng ALPHA = OUT }|.

      IF ls_dd01v-datatype = 'DEC' OR ls_dd01v-datatype = 'QUAN' OR ls_dd01v-datatype = 'CURR'.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Decimals: { ls_dd01v-decimals ALPHA = OUT }|.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_translation.

    DATA lt_fixed_values TYPE STANDARD TABLE OF dd07v.

    DATA ls_domain TYPE dd01v.

    DATA l_state TYPE ddobjstate.

    DATA(l_domain_name) = i_domain_name.

    l_domain_name = condense( to_upper( l_domain_name ) ).

    SELECT as4local, as4vers
      FROM dd01l
      INTO TABLE @DATA(lt_dd01l)
      WHERE domname = @l_domain_name.

    IF sy-subrc <> 0.
      r_response = |Domain { l_domain_name } doesn't exist.|.
      RETURN.
    ENDIF.

    READ TABLE lt_dd01l INTO DATA(ls_dd01l)
      WITH KEY as4vers = 'A'.

    IF me->is_active( l_domain_name ) = abap_true.
      l_state = 'A'.
    ENDIF.

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    CALL FUNCTION 'DDIF_DOMA_GET'
      EXPORTING
        name          = l_domain_name           " Name of the Domain to be Read
        state         = l_state                 " Read Status of the Domain
        langu         = l_language              " Language in which Texts are Read
      IMPORTING
        gotstate      = l_state                 " Status in which Reading took Place
        dd01v_wa      = ls_domain               " Header of the Domain
      TABLES
        dd07v_tab     = lt_fixed_values         " Fixed Domain Values
      EXCEPTIONS
        illegal_input = 1                       " Value not Allowed for Parameter
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Error while reading domain { l_domain_name }.|.
      RETURN.
    ENDIF.

    SELECT SINGLE sptxt
      FROM t002t
      WHERE spras = @sy-langu
        AND sprsl = @l_language
      INTO @DATA(l_language_description).

    r_response = |Domain: { l_domain_name }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Language: { l_language_description }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Short Description: { ls_domain-ddtext }{ cl_abap_char_utilities=>newline }|.
    r_response = |{ r_response }Fixed Values:|.

    LOOP AT lt_fixed_values ASSIGNING FIELD-SYMBOL(<ls_fixed_values>).
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Value:{ <ls_fixed_values>-domvalue_l } Text:{ <ls_fixed_values>-ddtext }|.
    ENDLOOP.

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

    DATA(l_domain_name) = i_domain_name.

    l_domain_name = condense( to_upper( l_domain_name ) ).

    l_objname = l_domain_name.

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_domain_name
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Domain { l_domain_name } not found.|.
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

    SELECT domname, ddlanguage, as4local, valpos, as4vers, ddtext, domvalue_l
      FROM dd07t
      WHERE domname = @l_domain_name
        AND ddlanguage = @ls_tadir-masterlang
        AND as4local = 'A'
        INTO TABLE @DATA(lt_dd07t).

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
      r_response = |Error updating translations. Domain: { l_domain_name }. Target language: { l_language }.|.
      RETURN.
    ENDIF.

    LOOP AT lt_pcx_s1 ASSIGNING FIELD-SYMBOL(<ls_pcx_s1>).
      <ls_pcx_s1>-t_text = i_short_description.
    ENDLOOP.

    CALL FUNCTION 'LXE_OBJ_TEXT_PAIR_READ_VALU'
      EXPORTING
        t_r3_lang = l_language
        s_r3_lang = ls_tadir-masterlang
        objtype   = 'VALU'
        objname   = l_objname
        read_only = ' '
      IMPORTING
        pstatus   = l_status
      TABLES
        lt_pcx_s1 = lt_pcx_s1_valu.

    LOOP AT i_t_fixed_values ASSIGNING FIELD-SYMBOL(<ls_fixed_values>).

      READ TABLE lt_dd07t ASSIGNING FIELD-SYMBOL(<ls_dd07t>)
        WITH KEY domvalue_l = <ls_fixed_values>-value.

      IF sy-subrc = 0.

        l_textkey = 'DDTEXT'.
        l_textkey+10 = '0' && <ls_dd07t>-valpos.

        READ TABLE lt_pcx_s1_valu ASSIGNING FIELD-SYMBOL(<ls_pcx_s1_valu>)
          WITH KEY textkey = l_textkey.

        IF sy-subrc = 0.

          <ls_pcx_s1_valu>-t_text = <ls_fixed_values>-description.

        ENDIF.

      ENDIF.

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
      r_response = |Error updating translations. Domain: { l_domain_name }. Target language: { l_language }.|.
      RETURN.
    ENDIF.

    CLEAR: l_status,
           l_error.

    CALL FUNCTION 'LXE_OBJ_TEXT_WRITE_VALU'
      EXPORTING
        r3_lang   = l_language
        objtype   = 'VALU'
        objname   = l_objname
      IMPORTING
        pstatus   = l_status
      TABLES
        lt_pcx_s1 = lt_pcx_s1_valu.

    IF l_status <> 'S'.
      r_response = |Error updating translations. Domain: { l_domain_name }. Target language: { l_language }.|.
      RETURN.
    ENDIF.

    lt_e071 = VALUE #( ( trkorr = l_transport_request
                         pgmid = 'LANG'
                         object = 'DOMD'
                         obj_name = l_domain_name
                         lang = l_language ) ).

    DATA(l_success) = NEW ycl_aai_fc_cts_api( )->add_object(
      EXPORTING
        i_transport_request = l_transport_request
      CHANGING
        ch_t_e071           = lt_e071
    ).

    IF l_success = abap_true.
      r_response = |Translations updated successfully. Domain: { l_domain_name }. Target language: { l_language }.|.
    ELSE.
      r_response = |Translations updated successfully but they were not added to the transport request { l_transport_request }. Domain: { l_domain_name }. Target language: { l_language }.|.
    ENDIF.

  ENDMETHOD.

  METHOD exists.

    SELECT SINGLE @abap_true
      FROM dd01l
      INTO @r_exists
      WHERE domname = @i_domain_name.

  ENDMETHOD.

  METHOD is_active.

    SELECT SINGLE @abap_true
      FROM dd01l
      INTO @r_active
      WHERE domname = @i_domain_name
        AND as4local = 'A'.

  ENDMETHOD.

  METHOD is_locked.

    DATA: lt_lock_entries TYPE STANDARD TABLE OF seqg3.

    DATA: l_argument TYPE seqg3-garg.

    r_locked = abap_false.

    l_argument = |{ mc_object }{ i_domain_name }|.

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
    DATA(l_update) = abap_false.
    DATA(l_search) = abap_true.
    DATA(l_get_translation) = abap_false.
    DATA(l_set_translation) = abap_false.


    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
          EXPORTING
            i_domain_name       = 'ZDO_TEST_DDIF_DOMA_PUT3'
            i_short_description = 'Test DDIF_DOMA_PUT'
            i_data_type         = 'CHAR'
            i_length            = 30
*            i_decimals          =
*            i_case_sensitive    =
            i_transport_request = 'NPLK900132'
            i_package           = 'Z001'
            i_t_fixed_values    = VALUE #( ( value = 'A' description = 'Description value A' ) )
        ).

      WHEN l_read.

        l_response = me->read( i_domain_name = 'ZDO_TEST_DDIF_DOMA_PUT' ).

      WHEN l_update.

        l_response = me->update(
          EXPORTING
            i_domain_name       = 'ZDO_TEST_DDIF_DOMA_PUT3'
            i_short_description = 'Test DDIF_DOMA_PUT Upd'
            i_data_type         = 'CHAR'
            i_length            = 35
*            i_decimals          =
*            i_case_sensitive    =
            i_transport_request = 'NPLK900132'
            i_t_fixed_values    = VALUE #( ( value = 'A' description = 'Description value A' )
                                           ( value = 'B' description = 'Description value B' ) )
        ).

      WHEN l_search.

        l_response = me->search( i_package = 'YAAI' i_domain_name = '' i_short_description = 'RAG' ).

      WHEN l_get_translation.

        l_response = me->get_translation( i_domain_name = 'ZDOTESTE' i_language    = 'P' ).

      WHEN l_set_translation.

        l_response = me->set_translation(
                       i_domain_name       = 'ZDO_STAT_TEST_TRANSLATION'
                       i_transport_request = 'NPLK900133'
                       i_language          = 'P'
                       i_short_description = 'Status'
                       i_t_fixed_values    = VALUE #( ( value = 'A' description = 'Em andamento' )
                                                      ( value = 'B' description = 'Bloqueado' )
                                                      ( value = 'F' description = 'Finalizado' )
                                                      ( value = 'P' description = 'Pendente' )
                                                      ( value = 'D' description = 'Aguardando' ) ) ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
