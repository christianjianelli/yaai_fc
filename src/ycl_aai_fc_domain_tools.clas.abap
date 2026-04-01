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
                i_domain_name     TYPE string
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
                i_domain_name     TYPE yde_aai_fc_domain OPTIONAL
                i_description     TYPE as4text OPTIONAL
                i_package         TYPE packname
      RETURNING VALUE(r_response) TYPE string.

    METHODS activate
      IMPORTING
                i_domain_name     TYPE yde_aai_fc_domain
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

    CALL FUNCTION 'DDIF_DOMA_ACTIVATE'
      EXPORTING
        name        = l_domain_name    " Name of the Data Element to be Activated
      EXCEPTIONS
        not_found   = 1                " Data Element not Found
        put_failure = 2                " Data Element could not be Written
        OTHERS      = 3.

    IF sy-subrc <> 0.

      r_response = |An error occurred while activating the domain { l_domain_name }.'|.

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

      r_response = |An error occurred while creating the TADIR entry for the newly created domain { l_domain_name } .|.

      RETURN.

    ENDIF.

    NEW ycl_aai_fc_cts_api( )->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              pgmid = mc_pgmid
                              object = mc_object
                              obj_name = l_domain_name )
      IMPORTING
        e_order    = DATA(l_order)
        e_task     = DATA(l_task)
        e_inserted = DATA(l_inserted)
    ).

    COMMIT WORK.

    r_response = |Domain { l_domain_name } created successfully.|.

  ENDMETHOD.

  METHOD read.

  ENDMETHOD.

  METHOD update.

    DATA lt_fixed_values TYPE STANDARD TABLE OF dd07v.

    DATA ls_domain TYPE dd01v.

    DATA l_state TYPE ddobjstate VALUE 'A'.

    CLEAR r_response.

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

    CALL FUNCTION 'DDIF_DOMA_GET'
      EXPORTING
        name          = l_domain_name    " Name of the Domain to be Read
        state         = l_state          " Read Status of the Domain
*       langu         = ' '              " Language in which Texts are Read
      IMPORTING
*       gotstate      =                  " Status in which Reading took Place
        dd01v_wa      = ls_domain        " Header of the Domain
      TABLES
        dd07v_tab     = lt_fixed_values  " Fixed Domain Values
      EXCEPTIONS
        illegal_input = 1                " Value not Allowed for Parameter
        OTHERS        = 2.

    IF sy-subrc <> 0.
      r_response = |Error reading domain { l_domain_name }.|.
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
    ENDIF.

    IF i_decimals IS NOT INITIAL.
      ls_domain-decimals = i_decimals.
    ENDIF.

    ls_domain-lowercase = i_case_sensitive.

    IF i_t_fixed_values IS NOT INITIAL.
      lt_fixed_values = i_t_fixed_values.
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

      r_response = |An error occurred while activating the domain { l_domain_name }.'|.

      RETURN.

    ENDIF.

    COMMIT WORK.

    r_response = |Domain { l_domain_name } updated successfully.|.

  ENDMETHOD.

  METHOD delete.

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

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_true.

    CASE abap_true.

      WHEN l_create.

        me->create(
          EXPORTING
            i_domain_name       = 'ZDO_TEST_DDIF_DOMA_PUT'
            i_short_description = 'Test DDIF_DOMA_PUT'
            i_data_type         = 'CHAR'
            i_length            = 30
*            i_decimals          = 2
*            i_case_sensitive    =
            i_transport_request = 'NPLK900133'
            i_package           = 'Z001'
            i_t_fixed_values    = VALUE #( ( value = 'A' description = 'Description value A' ) )
          RECEIVING
            r_response          = l_response
        ).

    ENDCASE.

    out->write( l_response ).

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

ENDCLASS.
