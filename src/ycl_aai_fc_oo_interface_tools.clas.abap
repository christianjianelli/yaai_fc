CLASS ycl_aai_fc_oo_interface_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid  VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'INTF'.

    METHODS read
      IMPORTING
                i_interface_name  TYPE yde_aai_fc_oo_interface_name
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_interface_name    TYPE yde_aai_fc_oo_interface_name OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_oo_interface_tools IMPLEMENTATION.

  METHOD read.

    DATA: lo_result_obj_intf     TYPE REF TO if_oo_clif_source,
          lo_object_source_class TYPE REF TO cl_oo_clif_source.

    DATA: l_version TYPE if_adt_tools_core_types=>ty_object-version,
          l_source  TYPE string.


    l_version = if_adt_uri_query_parameters=>co_version_active.

    lo_result_obj_intf = cl_oo_factory=>create_instance( )->create_clif_source(
        clif_name = i_interface_name
        version   = cl_adt_utility=>get_wb_version( l_version )
    ).

    TRY.
        lo_object_source_class ?= lo_result_obj_intf.
        lo_object_source_class->access_permission( access_mode = seok_access_show ).
      CATCH cx_oo_access_permission INTO DATA(lo_obj_err).
        IF lo_obj_err IS BOUND.
          RETURN.
        ENDIF.
      CATCH cx_sy_move_cast_error ##no_handler.
    ENDTRY.

    lo_object_source_class->get_source(
      IMPORTING
        source = DATA(lt_source)
    ).

    LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<l_line>).

      IF l_source IS INITIAL.
        l_source = <l_line> && cl_abap_char_utilities=>newline.
      ELSE.
        l_source = l_source  && <l_line> && cl_abap_char_utilities=>newline.
      ENDIF.

    ENDLOOP.

    r_response = l_source.

  ENDMETHOD.

  METHOD search.

    DATA: l_interface_name    TYPE string,
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
      r_response = |No interface found in package { l_package }.|.
      RETURN.
    ENDIF.

    l_interface_name = |*{ i_interface_name }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_interface_name IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_interface_name.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      SELECT SINGLE clsname, langu, descript
        FROM seoclasstx
        INTO @DATA(ls_seoclasstx)
        WHERE clsname = @<ls_tadir>-obj_name
          AND langu = @sy-langu.

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_seoclasstx-descript CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      r_response = |{ r_response }Interface: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_seoclasstx-descript }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_search) = abap_true.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_interface_name = 'YIF_AAI_CHAT'
        ).

      WHEN l_search.

        l_response = me->search(
          EXPORTING
            i_package = 'YAAI'
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
