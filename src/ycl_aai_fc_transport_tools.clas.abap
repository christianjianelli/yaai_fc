CLASS ycl_aai_fc_transport_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_workbench   TYPE string VALUE 'W',
               mc_customizing TYPE string VALUE 'C'.

    METHODS create
      IMPORTING
                i_description      TYPE as4text
                i_request_category TYPE yde_aai_fc_transp_req_categ OPTIONAL
      RETURNING VALUE(r_response)  TYPE string.

    METHODS read
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS search
      IMPORTING
                i_username            TYPE uname OPTIONAL
                i_modifiable          TYPE abap_bool
                i_released            TYPE abap_bool
                i_workbench           TYPE abap_bool
                i_customizing         TYPE abap_bool
                i_transport_of_copies TYPE abap_bool
                i_description         TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)     TYPE string.

    METHODS change_description
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
                i_description       TYPE as4text
      RETURNING VALUE(r_response)   TYPE string.

    METHODS release
      IMPORTING
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_current_transport_request
      IMPORTING
                i_object_type     TYPE e071-object
                i_object_name     TYPE e071-obj_name
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_fc_transport_tools IMPLEMENTATION.


  METHOD change_description.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    DATA(l_success) = lo_cts_api->change_request_description(
      EXPORTING
        i_transport_request = l_transport_request
        i_description       = CONV #( i_description )
    ).

    IF l_success = abap_true.
      r_response = |Transport request { l_transport_request } description changed.|.
    ELSE.
      r_response = |Transport request { l_transport_request } description not changed.|.
    ENDIF.

  ENDMETHOD.


  METHOD create.

    DATA l_transport_request TYPE trkorr.

    CLEAR r_response.

    DATA(l_request_category) = to_upper( i_request_category ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    CASE l_request_category.

      WHEN mc_workbench.

        l_transport_request = lo_cts_api->create(
          EXPORTING
            i_description = i_description
        ).

      WHEN mc_customizing.

        l_transport_request = lo_cts_api->create(
                                i_description = i_description
                                i_request_category = 'W'
                              ).

      WHEN OTHERS.

        l_transport_request = lo_cts_api->create(
          EXPORTING
            i_description = i_description
        ).

    ENDCASE.

    IF l_transport_request IS INITIAL.
      r_response = 'An error occurred while creating the transport request.'.
      RETURN.
    ENDIF.

    r_response = |Transport request { l_transport_request } created successfully|.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_true.
    DATA(l_search) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
          EXPORTING
            i_description = 'Test customizing request tool'
            i_request_category = 'C'
        ).

      WHEN l_search.

        l_response = me->search(
*                       i_username            =
                       i_modifiable          = abap_true
                       i_released            = abap_false
                       i_workbench           = abap_true
                       i_customizing         = abap_false
                       i_transport_of_copies = abap_false
*                       i_description         =
                     ).

      WHEN l_read.

        l_response = me->read( 'NPLK900110' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.


  METHOD read.

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
        e_t_objects         = DATA(lt_objects)
    ).

    DATA(l_status) = COND string( WHEN ls_header-trstatus = 'D' THEN 'Modifiable' ELSE 'Released' ).

    DATA(l_user) = CONV string( ls_header-as4user ).

    IF sy-uname = ls_header-as4user.
      l_user = |{ l_user } (the current username you are logged in as)|.
    ENDIF.

    r_response = |Transport request: { l_transport_request }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_header-as4text }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Status: { l_status }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Owner (username): { l_user }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Objects:|.

    LOOP AT lt_objects ASSIGNING FIELD-SYMBOL(<ls_object>).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - { <ls_object>-pgmid } { <ls_object>-object } { <ls_object>-obj_name }|.

    ENDLOOP.

  ENDMETHOD.


  METHOD release.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    lo_cts_api->release(
      EXPORTING
        i_transport_request    = l_transport_request
        i_test_mode            = abap_false
        i_ignore_locks         = abap_true
      IMPORTING
        e_released             = DATA(l_released)
        e_error                = DATA(l_error)
    ).

    IF l_released = abap_true.
      r_response = |Transport request { l_transport_request } released.|.
    ELSE.
      r_response = |Transport request { l_transport_request } not released. Error: { l_error }.|.
    ENDIF.

  ENDMETHOD.


  METHOD search.

    DATA: lt_trstatus   TYPE RANGE OF e070-trstatus,
          lt_trfunction TYPE RANGE OF e070-trfunction.

    DATA: l_username TYPE syst-uname,
          l_type     TYPE string,
          l_status   TYPE string.

    CLEAR r_response.

    l_username = sy-uname.

    IF i_username IS NOT INITIAL.
      l_username = to_upper( condense( i_username ) ).
    ENDIF.

    APPEND VALUE #( sign = 'I' option = 'EQ' low = '?' ) TO lt_trstatus.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = '?' ) TO lt_trfunction.

    IF i_modifiable = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = 'D' ) TO lt_trstatus.
    ENDIF.

    IF i_released = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = 'R' ) TO lt_trstatus.
    ENDIF.

    IF i_workbench = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = 'K' ) TO lt_trfunction.
    ENDIF.

    IF i_customizing = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = 'W' ) TO lt_trfunction.
    ENDIF.

    IF i_transport_of_copies = abap_true.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = 'T' ) TO lt_trfunction.
    ENDIF.

    SELECT a~trkorr, b~as4text, a~trfunction, a~trstatus
      FROM e070 AS a
      LEFT OUTER JOIN e07t AS b
      ON a~trkorr = b~trkorr
      AND b~langu = @sy-langu
      WHERE a~as4user = @l_username
        AND a~trfunction IN @lt_trfunction
        AND a~trstatus IN @lt_trstatus
      INTO TABLE @DATA(lt_transport_requests).

    IF sy-subrc <> 0.
      r_response = 'No transport request found.'.
      RETURN.
    ENDIF.

    DATA(l_description) = i_description.

    IF l_description IS NOT INITIAL.
      l_description = |*{ l_description }*|.
    ENDIF.

    LOOP AT lt_transport_requests ASSIGNING FIELD-SYMBOL(<ls_transport_request>).

      IF l_description IS NOT INITIAL.
        IF NOT <ls_transport_request>-as4text CP l_description.
          CONTINUE.
        ENDIF.
      ENDIF.

      l_type = COND #( WHEN <ls_transport_request>-trfunction = 'K'
                       THEN 'Workbench'
                       WHEN <ls_transport_request>-trfunction = 'W'
                       THEN 'Customizing'
                       WHEN <ls_transport_request>-trfunction = 'T'
                       THEN 'Transport of copies'
                       ELSE space ).

      l_status = COND #( WHEN <ls_transport_request>-trstatus = 'D'
                         THEN 'Modifiable'
                         ELSE 'Released' ).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Transport Request: { <ls_transport_request>-trkorr }, Type: { l_type }, Status: { l_status }, Description: { <ls_transport_request>-as4text } |.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = 'No transport request found.'.
      RETURN.
    ENDIF.

    r_response = 'Here is the list of the modifiable transport requests found:' && r_response.

  ENDMETHOD.

  METHOD get_current_transport_request.

    DATA(l_object_name) = i_object_name.
    DATA(l_object_type) = i_object_type.

    l_object_name = to_lower( condense( l_object_name ) ).
    l_object_type = to_lower( condense( l_object_type ) ).

    NEW ycl_aai_fc_cts_api( )->get_current_transport_request(
      EXPORTING
        i_object_name       = l_object_name
        i_object            = l_object_type
      IMPORTING
        e_transport_request = DATA(l_transport_request)
    ).

    r_response = l_transport_request.

  ENDMETHOD.
ENDCLASS.
