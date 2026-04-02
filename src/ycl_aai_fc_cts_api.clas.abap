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
        AND as4user = @sy-uname
      INTO @r_is_valid.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.

    DATA(l_add_object) = abap_true.

    CASE abap_true.

      WHEN l_create.

        DATA(l_transport_request) = me->create(
          EXPORTING
            i_description       = 'Test API'
        ).

        l_response = l_transport_request.

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
