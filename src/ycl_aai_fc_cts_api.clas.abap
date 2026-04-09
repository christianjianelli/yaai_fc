CLASS ycl_aai_fc_cts_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS create
      IMPORTING
                i_description              TYPE string
                i_request_category         TYPE trfunction DEFAULT 'K'
      RETURNING VALUE(r_transport_request) TYPE trkorr.

    METHODS read
      IMPORTING
        i_transport_request TYPE trkorr
      EXPORTING
        e_s_header          TYPE trwbo_request_header
        e_t_objects         TYPE trwbo_t_e071.

    METHODS add_object
      IMPORTING
                i_transport_request TYPE trkorr
      CHANGING
                ch_t_e071           TYPE trwbo_t_e071
                ch_t_e071k          TYPE trwbo_t_e071k OPTIONAL
      RETURNING VALUE(r_success)    TYPE abap_bool.

    METHODS is_valid
      IMPORTING
                i_order           TYPE trkorr
      RETURNING VALUE(r_is_valid) TYPE abap_bool.

    METHODS insert_object
      IMPORTING
        i_s_object          TYPE ko200
        i_object_class      TYPE csequence
        i_package           TYPE devclass
        i_language          TYPE spras
      EXPORTING
        e_transport_request TYPE trkorr
        e_task              TYPE trkorr
        e_inserted          TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_cts_api IMPLEMENTATION.

  METHOD create.

    CLEAR r_transport_request.

    TRY.

        r_transport_request = NEW cl_cts_rest_api_impl( )->if_cts_rest_api~create_request(
          EXPORTING
            iv_description      = CONV #( i_description )         " Short Description of Repository Objects
            iv_request_category = i_request_category              " Type of Request/Task
            it_users            = VALUE #( ( user = sy-uname      " Tasks for Users
                                             type = 'S' ) ) ).

      CATCH cx_cts_rest_api_exception ##NO_HANDLER. " CTS REST API Exception

    ENDTRY.

  ENDMETHOD.

  METHOD read.

    DATA ls_request TYPE trwbo_request.

    TRY.

        DATA(lo_cts_api) = NEW cl_cts_rest_api_impl( ).

        lo_cts_api->if_cts_rest_api~get_request_and_tasks(
          EXPORTING
            iv_trkorr   = i_transport_request
          IMPORTING
            et_requests = DATA(lt_requests)
        ).

        LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<ls_request>).

          ls_request-h-trkorr = <ls_request>-trkorr.

          lo_cts_api->if_cts_rest_api~get_request_data(
            EXPORTING
              iv_read_headers    = abap_true
              iv_read_descr      = abap_true
              iv_read_objs       = abap_true
            CHANGING
              cs_request         = ls_request
          ).

          IF <ls_request>-trkorr = i_transport_request.
            e_s_header = ls_request-h.
          ENDIF.

          APPEND LINES OF ls_request-objects TO e_t_objects.

          CLEAR ls_request.

        ENDLOOP.

        SORT e_t_objects BY pgmid object obj_name.

        DELETE ADJACENT DUPLICATES FROM e_t_objects COMPARING pgmid object obj_name.

      CATCH cx_cts_rest_api_exception ##NO_HANDLER. " CTS REST API Exception

    ENDTRY.

  ENDMETHOD.

  METHOD add_object.

    r_success = abap_false.

    TRY.

        NEW cl_cts_rest_api_impl( )->if_cts_rest_api~add_object_to_request(
          EXPORTING
            iv_trkorr = i_transport_request
          CHANGING
            ct_e071   = ch_t_e071[]
            ct_e071k  = ch_t_e071k[]
        ).

        r_success = abap_true.

      CATCH cx_cts_rest_api_exception ##NO_HANDLER. " CTS REST API Exception

    ENDTRY.

  ENDMETHOD.

  METHOD insert_object.

    DATA l_use_korrnum_immediatedly TYPE abap_bool.

    CLEAR: e_inserted.

    DO 2 TIMES.

      CALL FUNCTION 'RS_CORR_INSERT'
        EXPORTING
          object                   = |{ i_s_object-object }{ i_s_object-obj_name }|
          object_class             = i_object_class
          devclass                 = i_package
          master_language          = i_language
          korrnum                  = i_s_object-trkorr
          use_korrnum_immediatedly = l_use_korrnum_immediatedly
          mode                     = 'INSERT'
          global_lock              = abap_true
          suppress_dialog          = abap_true
        IMPORTING
          ordernum                 = e_transport_request
          korrnum                  = e_task
        EXCEPTIONS
          cancelled                = 1
          permission_failure       = 2
          unknown_objectclass      = 3
          OTHERS                   = 4.

      IF sy-subrc = 0.
        e_inserted = abap_true.
        EXIT.
      ENDIF.

      l_use_korrnum_immediatedly = abap_true.

    ENDDO.

  ENDMETHOD.

  METHOD is_valid.

    SELECT SINGLE @abap_true
      FROM e070
      WHERE trkorr = @i_order
        AND trstatus = 'D'        "Modifiable
        AND as4user = @sy-uname
      INTO @r_is_valid.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_true.
    DATA(l_add_object) = abap_false.

    CASE abap_true.

      WHEN l_create.

        DATA(l_transport_request) = me->create(
          EXPORTING
            i_description       = 'Test API'
        ).

        l_response = l_transport_request.

      WHEN l_read.

        me->read(
          EXPORTING
            i_transport_request = 'NPLK900129'
          IMPORTING
            e_s_header          = DATA(ls_header)
            e_t_objects         = DATA(lt_objects)
        ).

        l_response = |{ ls_header-trkorr }  { ls_header-as4text } ( Number of objects: { lines( lt_objects ) })|.

      WHEN l_add_object.

        DATA lt_e071 TYPE trwbo_t_e071.

        lt_e071 = VALUE #( ( trkorr = 'NPLK900133'
                             pgmid = 'R3TR'
                             object = 'DOMA'
                             obj_name = 'ZDO_TEST_DDIF_DOMA_PUT3'
                             lockflag = 'X' ) ).

        me->add_object(
          EXPORTING
            i_transport_request = 'NPLK900133'
          CHANGING
            ch_t_e071           = lt_e071
*            ch_t_e071k          =
          RECEIVING
            r_success           = DATA(l_success)
        ).

        IF l_success = abap_true.
          l_response = 'Object was added to transport request'.
        ELSE.
          l_response = 'Object was NOT added to transport request'.
        ENDIF.

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
