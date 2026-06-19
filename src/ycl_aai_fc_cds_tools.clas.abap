CLASS ycl_aai_fc_cds_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'DDLS'.

    METHODS create
      IMPORTING
                i_name              TYPE yde_aai_fc_cds_view
                i_short_description TYPE as4text
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
                i_source            TYPE string
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_name            TYPE yde_aai_fc_cds_view
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_name              TYPE yde_aai_fc_cds_view OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_name              TYPE yde_aai_fc_cds_view
                i_short_description TYPE as4text OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_source            TYPE string
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_name              TYPE yde_aai_fc_cds_view
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS check
      IMPORTING
                i_name            TYPE yde_aai_fc_cds_view
      RETURNING VALUE(r_response) TYPE string.

    METHODS get_current_transport_request
      IMPORTING
                i_name            TYPE yde_aai_fc_cds_view
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _exists
      IMPORTING
                i_name          TYPE yde_aai_fc_cds_view
      RETURNING VALUE(r_exists) TYPE abap_bool.

    METHODS _get_package
      IMPORTING
                i_name           TYPE yde_aai_fc_cds_view
      RETURNING VALUE(r_package) TYPE devclass.


ENDCLASS.



CLASS ycl_aai_fc_cds_tools IMPLEMENTATION.


  METHOD check.

    DATA lt_error_list TYPE if_ddic_wb_ddls_svc=>ty_error_wb_tab.

    DATA l_objkey  TYPE seu_objkey.
    DATA l_version TYPE as4local.

    DATA lo_object_data TYPE REF TO cl_ddic_wb_ddls_object_data.

    FREE r_response.

    DATA(lo_ddls_svc) = cl_ddic_wb_ddls_svc=>get_ddls_svc_instance( ).

    l_objkey = to_upper( condense( i_name ) ).

    l_version = 'N'.

    lo_object_data = NEW #( ).

    TRY.

        lo_ddls_svc->read_ddls(
          EXPORTING
            ddls_object_key = l_objkey
            object_data     = lo_object_data
          CHANGING
            version         = l_version
        ).

        lo_ddls_svc->check(
          EXPORTING
            object_data = lo_object_data
          IMPORTING
            error_list  = lt_error_list
        ).

        LOOP AT lt_error_list ASSIGNING FIELD-SYMBOL(<ls_error>).

          IF <ls_error>-msgty = 'E'.

            MESSAGE ID <ls_error>-msgid
                    TYPE <ls_error>-msgty
                    NUMBER <ls_error>-msgno
                    WITH <ls_error>-msgv1
                    <ls_error>-msgv2
                    <ls_error>-msgv3
                    <ls_error>-msgv4 INTO DATA(l_message_text).

            IF r_response IS NOT INITIAL.
              r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
            ENDIF.

            r_response = |{ r_response } Error: line { <ls_error>-line }, column { <ls_error>-column }, { l_message_text }|.

          ENDIF.

        ENDLOOP.

      CATCH cx_swb_object_does_not_exist. " The requested object does not exist

      CATCH cx_swb_exception.             " ABAP Workbench: Exception

    ENDTRY.

    r_response = |No errors found in the CDS view { i_name }|.

  ENDMETHOD.


  METHOD create.

    DATA ls_ddddlsrcv_wa TYPE ddddlsrcv.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    ls_ddddlsrcv_wa-ddtext = i_short_description.
    ls_ddddlsrcv_wa-ddlname = condense( to_upper( i_name ) ).
    ls_ddddlsrcv_wa-source = i_source.
    ls_ddddlsrcv_wa-ddlanguage = sy-langu.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    DATA(lo_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).

    TRY.

        lo_ddl_handler->save(
          EXPORTING
            name             = ls_ddddlsrcv_wa-ddlname
            put_state        = 'N'
            ddddlsrcv_wa     = ls_ddddlsrcv_wa
        ).

        lo_ddl_handler->write_tadir(
          EXPORTING
            objectname = ls_ddddlsrcv_wa-ddlname
            devclass   = l_package
            prid       = 0
        ).

        lo_ddl_handler->activate(
          EXPORTING
            name = ls_ddddlsrcv_wa-ddlname
        ).

      CATCH cx_dd_ddl_save
            cx_dd_ddl_activate
            INTO DATA(lo_ex).

        r_response = |Error: { lo_ex->get_text( ) }|.

        RETURN.

    ENDTRY.

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = ls_ddddlsrcv_wa-ddlname )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    r_response = |CDS view { ls_ddddlsrcv_wa-ddlname } created successfully.|.

    IF l_inserted = abap_false.
      r_response = |{ r_response } An error occurred and it was not added to the transport request { l_transport_request }.|.
    ENDIF.

  ENDMETHOD.

  METHOD read.

    DATA l_name TYPE ddlname.

    FREE r_response.

    l_name = condense( to_upper( i_name ) ).

    IF me->_exists( l_name ) = abap_false.

      r_response = |CDS view { i_name } not found.|.

      RETURN.

    ENDIF.

    DATA(lo_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).

    TRY.

        lo_ddl_handler->read(
          EXPORTING
            name         = l_name
          IMPORTING
            ddddlsrcv_wa = DATA(ls_ddlsrcv_wa)
        ).

        IF ls_ddlsrcv_wa IS NOT INITIAL.
          r_response = ls_ddlsrcv_wa-source.
        ELSE.

          r_response = |CDS view { i_name } not found.|.

        ENDIF.

      CATCH cx_dd_ddl_read INTO DATA(lo_ex).

        r_response = lo_ex->get_text( ).

    ENDTRY.

  ENDMETHOD.

  METHOD search.

    DATA: l_name              TYPE ddlname,
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
      r_response = |No CDS view found.|.
      RETURN.
    ENDIF.

    l_name = |*{ i_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF i_name IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_name.
          CONTINUE.
        ENDIF.

      ENDIF.

      SELECT ddlname, ddlanguage, ddtext
        FROM ddddlsrct
        WHERE ddlname = @<ls_tadir>-obj_name
          AND ddlanguage = @<ls_tadir>-masterlang
        INTO @DATA(ls_ddddlsrct)
        UP TO 1 ROWS.
      ENDSELECT.

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_ddddlsrct-ddtext CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }CDS view: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_ddddlsrct-ddtext }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |No CDS view found.|.
    ENDIF.

  ENDMETHOD.

  METHOD update.

    DATA ls_ddddlsrcv_wa TYPE ddddlsrcv.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    ls_ddddlsrcv_wa-ddtext = i_short_description.
    ls_ddddlsrcv_wa-ddlname = condense( to_upper( i_name ) ).
    ls_ddddlsrcv_wa-source = i_source.
    ls_ddddlsrcv_wa-ddlanguage = sy-langu.

    IF me->_exists( ls_ddddlsrcv_wa-ddlname ) = abap_false.

      r_response = |CDS view { i_name } not found.|.

      RETURN.

    ENDIF.

    DATA(l_package) = me->_get_package( i_name = ls_ddddlsrcv_wa-ddlname ).

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = ls_ddddlsrcv_wa-ddlname )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.
      r_response = |An error occurred and it was not possible to use the transport request { l_transport_request } to record the change.|.
      RETURN.
    ENDIF.

    DATA(lo_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).

    TRY.

        lo_ddl_handler->save(
          EXPORTING
            name             = ls_ddddlsrcv_wa-ddlname
            put_state        = 'N'
            ddddlsrcv_wa     = ls_ddddlsrcv_wa
        ).

        lo_ddl_handler->activate(
          EXPORTING
            name = ls_ddddlsrcv_wa-ddlname
        ).

      CATCH cx_dd_ddl_save
            cx_dd_ddl_activate
            INTO DATA(lo_ex).

        r_response = |Error: { lo_ex->get_text( ) }|.

        RETURN.

    ENDTRY.

    r_response = |CDS view { ls_ddddlsrcv_wa-ddlname } updated successfully.|.

  ENDMETHOD.

  METHOD delete.

    DATA l_name TYPE ddlname.

    FREE r_response.

    l_name = condense( to_upper( i_name ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    IF me->_exists( l_name ) = abap_false.
      r_response = |CDS view { i_name } not found.|.
      RETURN.
    ENDIF.

    DATA(l_package) = me->_get_package( i_name = l_name ).

    lo_cts_api->insert_object(
      EXPORTING
        i_s_object = VALUE #( trkorr = l_transport_request
                              object = mc_object
                              obj_name = l_name )
        i_object_class = 'DICT'
        i_package = l_package
        i_language = sy-langu
      IMPORTING
        e_inserted = DATA(l_inserted)
    ).

    IF l_inserted = abap_false.
      r_response = |An error occurred and it was not possible to use the transport request { l_transport_request } to record the change.|.
      RETURN.
    ENDIF.

    DATA(lo_ddl_handler) = cl_dd_ddl_handler_factory=>create( ).

    TRY.

        lo_ddl_handler->delete(
          EXPORTING
            name = l_name
        ).

      CATCH cx_dd_ddl_delete INTO DATA(lo_ex).

        r_response = lo_ex->get_text( ).

        RETURN.

    ENDTRY.

    r_response = |CDS view { l_name } deleted successfully.|.

  ENDMETHOD.

  METHOD get_current_transport_request.

    DATA(l_cds_view_name) = i_name.

    l_cds_view_name = condense( to_upper( l_cds_view_name ) ).

    NEW ycl_aai_fc_cts_api( )->get_current_transport_request(
      EXPORTING
        i_object_name       = l_cds_view_name
        i_pgmid             = mc_pgmid
        i_object            = mc_object
      IMPORTING
        e_transport_request = DATA(l_transport_request)
    ).

    r_response = l_transport_request.

  ENDMETHOD.

  METHOD _exists.

    SELECT SINGLE @abap_true
      FROM dd02b
      INTO @r_exists
      WHERE strucobjn = @i_name.

  ENDMETHOD.

  METHOD _get_package.

    SELECT SINGLE devclass
      FROM tadir
      WHERE pgmid = @me->mc_pgmid
        AND object = @me->mc_object
        AND obj_name = @i_name
       INTO @r_package.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.
    DATA l_source TYPE string.
    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_true.
    DATA(l_update) = abap_false.
    DATA(l_delete) = abap_false.
    DATA(l_check) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_source = |@AbapCatalog.sqlViewName: 'ZVW_TEST_XX' { cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@AbapCatalog.compiler.compareFilter: true{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@AbapCatalog.preserveKey: true{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@AccessControl.authorizationCheck: #CHECK{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@EndUserText.label: 'Test CDS View create tool'{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }define view ZI_TEST_XX{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }  as select from tvarvc{ cl_abap_char_utilities=>newline }|.
        l_source = l_source && '{' && cl_abap_char_utilities=>newline.
        l_source = |{ l_source }  key name,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }  key type,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }  key numb,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      sign,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      opti,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      low,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      high{ cl_abap_char_utilities=>newline }|.
        l_source = l_source && '}' && cl_abap_char_utilities=>newline.

        l_response = me->create(
          EXPORTING
            i_name              = 'ZI_TEST_XX'
            i_short_description = 'Test CDS View create tool'
            i_transport_request = 'NPLK900125'
            i_package           = 'Z001'
            i_source            = l_source
        ).

      WHEN l_read.

        l_response = me->read( i_name = 'ZI_TEST_XX' ).

      WHEN l_search.

        l_response = me->search(
                       i_package           = 'Z001'
*                       i_name              = 'XX'
*                       i_short_description = 'create'
                     ).

      WHEN l_update.

        l_source = |@AbapCatalog.sqlViewName: 'ZVW_TEST_XX' { cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@AbapCatalog.compiler.compareFilter: true{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@AbapCatalog.preserveKey: true{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@AccessControl.authorizationCheck: #CHECK{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }@EndUserText.label: 'Test CDS View create tool'{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }define view ZI_TEST_XX{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }  as select from tvarvc{ cl_abap_char_utilities=>newline }|.
        l_source = l_source && '{' && cl_abap_char_utilities=>newline.
        l_source = |{ l_source }  key name,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }  key type,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }  key numb,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      sign,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      opti,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      low,{ cl_abap_char_utilities=>newline }|.
        l_source = |{ l_source }      high{ cl_abap_char_utilities=>newline }|.
        l_source = l_source && '}' && cl_abap_char_utilities=>newline.

        l_response = me->update(
          EXPORTING
            i_name              = 'ZI_TEST_XX'
            i_short_description = 'Test CDS View create tool'
            i_transport_request = 'NPLK900125'
            i_source            = l_source
        ).

      WHEN l_delete.

        l_response = me->delete( i_name = 'ZI_TEST_XX' i_transport_request = 'NPLK900125' ).

      WHEN l_check.

        l_response = me->check( i_name = 'ZI_TEST_XX' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.
ENDCLASS.
