CLASS ycl_aai_fc_cts_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS create
      IMPORTING
                i_description              TYPE string
                i_package                  TYPE string
      RETURNING VALUE(r_transport_request) TYPE trkorr.

    METHODS insert_object
      IMPORTING
        i_s_object TYPE ko200
      EXPORTING
        e_order    TYPE e070-trkorr
        e_task     TYPE e070-trkorr
        e_inserted TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_cts_api IMPLEMENTATION.

  METHOD create.

    CLEAR r_transport_request.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

  ENDMETHOD.

  METHOD insert_object.

    CLEAR: e_order,
           e_task,
           e_inserted.

    CALL FUNCTION 'TRINT_CORR_INSERT'
      EXPORTING
        iv_order          = i_s_object-trkorr
        is_ko200          = i_s_object
*       iv_no_standard_editor = ' '
*       iv_no_show_option = 'X'
*       iv_dialog         = 'X'
      IMPORTING
        we_order          = e_order
        we_task           = e_task
*       es_ko200          =
*       es_tadir          =
        ev_append         = e_inserted
      EXCEPTIONS
        cancel_edit_error = 1
        show_only_error   = 2
        OTHERS            = 3.

    IF sy-subrc <> 0.
      e_inserted = abap_false.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
