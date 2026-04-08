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
                i_description     TYPE as4text OPTIONAL
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_fc_transport_tools IMPLEMENTATION.

  METHOD create.

    DATA l_transport_request TYPE trkorr.

    CLEAR r_response.

    DATA(l_request_category) = to_upper( i_request_category ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    CASE l_request_category.

      WHEN mc_workbench.

        l_transport_request = lo_cts_api->create(
          EXPORTING
            i_description = CONV #( i_description )
        ).

      WHEN mc_customizing.

        l_transport_request = lo_cts_api->create(
                                i_description = CONV #( i_description )
                                i_request_category = 'W'
                              ).

      WHEN OTHERS.

        l_transport_request = lo_cts_api->create(
          EXPORTING
            i_description = CONV #( i_description )
        ).

    ENDCASE.

    IF l_transport_request IS INITIAL.
      r_response = 'An error occurred while creating the transport request.'.
      RETURN.
    ENDIF.

    r_response = |Transport request { l_transport_request } created successfully|.

  ENDMETHOD.

  METHOD read.

  ENDMETHOD.

  METHOD search.

    DATA l_type TYPE string.

    CLEAR r_response.

    SELECT a~trkorr, b~as4text, trfunction
      FROM e070 AS a
      LEFT OUTER JOIN e07t AS b
      ON a~trkorr = b~trkorr
      AND b~langu = @sy-langu
      WHERE a~as4user = @sy-uname
        AND a~trfunction IN ( 'W', 'K' )
        AND a~trstatus = 'D'
      INTO TABLE @DATA(lt_transport_requests).

    IF sy-subrc <> 0.
      r_response = 'No transport requests found.'.
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

      l_type = COND #( WHEN <ls_transport_request>-trfunction = 'K' THEN 'Workbench' ELSE 'Customizing' ).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Transport Request: { <ls_transport_request>-trkorr }, Type: { l_type }, Description: { <ls_transport_request>-as4text } |.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = 'No transport requests found.'.
      RETURN.
    ENDIF.

    r_response = 'Here is the list of the modifiable transport requests found:' && r_response.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_search) = abap_true.

    DATA(l_add_object) = abap_true.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
          EXPORTING
            i_description = 'Test customizing request tool'
            i_request_category = 'C'
        ).

      WHEN l_search.

        l_response = me->search( 'AI' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
