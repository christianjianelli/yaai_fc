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

    METHODS sort_and_compress
      IMPORTING
                i_transport_request TYPE trkorr
      RETURNING VALUE(r_success)    TYPE abap_bool.

    METHODS release
      IMPORTING
        i_transport_request    TYPE trkorr
        i_test_mode            TYPE abap_bool DEFAULT abap_false
        i_ignore_locks         TYPE abap_bool DEFAULT abap_true
        i_ignore_objects_check TYPE abap_bool DEFAULT abap_true
      EXPORTING
        e_released             TYPE abap_bool
        e_error                TYPE string.

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

  METHOD sort_and_compress.

    r_success = abap_false.

    TRY.

        NEW cl_cts_rest_api_impl( )->if_cts_rest_api~sort_and_compress(
          EXPORTING
            iv_trkorr      = i_transport_request
          IMPORTING
            es_request     = DATA(ls_request)
        ).

        r_success = abap_true.

      CATCH cx_cts_rest_api_exception ##NO_HANDLER. " CTS REST API Exception

    ENDTRY.

  ENDMETHOD.

  METHOD release.

    DATA lo_ex_cts_rest_api TYPE REF TO cx_cts_rest_api_exception.

    DATA l_ignorable_errors TYPE abap_bool.

    CLEAR e_error.

    e_released = abap_false.

    me->sort_and_compress( i_transport_request ).

    TRY.

        NEW cl_cts_rest_api_impl( )->if_cts_rest_api~release(
          EXPORTING
            iv_trkorr               = i_transport_request
            iv_simulation           = i_test_mode
            iv_ignore_locks         = i_ignore_locks
            iv_ignore_objects_check = i_ignore_objects_check
          IMPORTING
            et_messages   = DATA(lt_messages)
        ).

        e_released = abap_true.

      CATCH cx_cts_rest_api_release_fail   INTO lo_ex_cts_rest_api. " Error when releasing request or task
      CATCH cx_cts_rest_api_obj_lock_displ INTO lo_ex_cts_rest_api. " Ignorable errors when attempting to lock objects

        l_ignorable_errors = abap_true.

      CATCH cx_cts_rest_api_obj_lock_error INTO lo_ex_cts_rest_api. " Lock error
      CATCH cx_cts_rest_api_inac_obj_error INTO lo_ex_cts_rest_api. " Inactive object error
      CATCH cx_cts_rest_api_crit_obj_error INTO lo_ex_cts_rest_api. " Critical object check error
      CATCH cx_cts_rest_api_disp_obj_error INTO lo_ex_cts_rest_api. " Non-critical object check error
      CATCH cx_cts_rest_api_req_cons_error INTO lo_ex_cts_rest_api. " Request is not consistent
      CATCH cx_cts_rest_api_obchk_obsolete INTO lo_ex_cts_rest_api. " Object check is not up-to-date
      CATCH cx_cts_rest_api_exception      INTO lo_ex_cts_rest_api. " CTS REST API Exception

    ENDTRY.

    IF lo_ex_cts_rest_api IS BOUND.

      IF l_ignorable_errors = abap_true.

        e_released = abap_true.

        RETURN.

      ENDIF.

      DATA(l_error) = lo_ex_cts_rest_api->get_text( ).

      e_error = l_error.

      LOOP AT lt_messages ASSIGNING FIELD-SYMBOL(<ls_message>).

        MESSAGE ID <ls_message>-msgid
          TYPE <ls_message>-msgty
          NUMBER <ls_message>-msgno
          WITH <ls_message>-msgv1 <ls_message>-msgv2 <ls_message>-msgv3 <ls_message>-msgv4
          INTO DATA(l_message).

        IF l_message <> l_error.

          e_error = |{ e_error }{ cl_abap_char_utilities=>newline }{ l_message }|.

        ENDIF.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_add_object) = abap_false.
    DATA(l_sort_and_compress) = abap_false.
    DATA(l_release)  = abap_true.

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

      WHEN l_sort_and_compress.

        l_success = me->sort_and_compress( 'NPLK900126' ).

        IF l_success = abap_true.
          l_response = 'Transport request/task sorted and compressed.'.
        ELSE.
          l_response = 'Transport request/task sort and compress failed.'.
        ENDIF.

      WHEN l_release.

        me->release(
          EXPORTING
            i_transport_request = 'NPLK900120'
            i_test_mode = abap_false
          IMPORTING
            e_released = l_success
            e_error = DATA(l_error)
        ).

        IF l_success = abap_true.
          l_response = 'Transport request/task NPLK900120 released.'.
        ELSE.
          l_response = 'Transport request/task NPLK900120 release failed.'.
          l_response = |{ l_response }{ cl_abap_char_utilities=>newline }{ l_error }|.
        ENDIF.

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
