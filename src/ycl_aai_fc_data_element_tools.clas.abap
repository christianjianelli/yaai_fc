CLASS ycl_aai_fc_data_element_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS create
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_short_description TYPE as4text
                i_domain_name       TYPE yde_aai_fc_domain OPTIONAL
                i_data_type         TYPE yde_aai_fc_data_type OPTIONAL
                i_length            TYPE yde_aai_fc_length OPTIONAL
                i_decimals          TYPE yde_aai_fc_decimals OPTIONAL
                i_label_short       TYPE scrtext_s
                i_label_medium      TYPE scrtext_m
                i_label_long        TYPE scrtext_l
                i_label_heading     TYPE reptext
                i_transport_request TYPE yde_aai_fc_transport_request
                i_package           TYPE packname
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_short_description TYPE as4text OPTIONAL
                i_domain_name       TYPE yde_aai_fc_domain OPTIONAL
                i_data_type         TYPE yde_aai_fc_data_type OPTIONAL
                i_length            TYPE yde_aai_fc_length OPTIONAL
                i_decimals          TYPE yde_aai_fc_decimals OPTIONAL
                i_label_short       TYPE scrtext_s OPTIONAL
                i_label_medium      TYPE scrtext_m OPTIONAL
                i_label_long        TYPE scrtext_l OPTIONAL
                i_label_heading     TYPE reptext OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS activate
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
      RETURNING VALUE(r_activated)  TYPE abap_bool.

    METHODS set_translation
      IMPORTING
                i_data_element_name TYPE yde_aai_fc_data_element
                i_transport_request TYPE yde_aai_fc_transport_request
                i_language          TYPE spras
                i_short_description TYPE as4text
                i_label_short       TYPE scrtext_s
                i_label_medium      TYPE scrtext_m
                i_label_long        TYPE scrtext_l
                i_label_heading     TYPE reptext
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_translation
      IMPORTING
                i_data_element_name TYPE string
                i_language          TYPE spras
      RETURNING VALUE(r_response)   TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_fc_data_element_tools IMPLEMENTATION.

  METHOD create.

    DATA ls_data_element TYPE dd04v.

    DATA(l_data_element) = i_data_element_name.

    l_data_element = condense( to_upper( l_data_element ) ).

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    IF i_data_type IS NOT INITIAL.

      NEW ycl_aai_ddic_tools_util( )->determine_data_type(
        EXPORTING
          i_data_type = i_data_type
        IMPORTING
          e_data_type = DATA(l_data_type)
          e_error     = DATA(l_error)
      ).

      IF l_data_type IS INITIAL.

        RETURN.

      ENDIF.

    ENDIF.

    ls_data_element-rollname = l_data_element.
    ls_data_element-ddlanguage = sy-langu.
    ls_data_element-domname = condense( to_upper( i_domain_name ) ).
*    ROUTPUTLEN
*    MEMORYID
*    LOGFLAG
*    HEADLEN
*    SCRLEN1
*    SCRLEN2
*    SCRLEN3
    ls_data_element-ddtext = i_short_description.
    ls_data_element-reptext = i_label_heading.
    ls_data_element-scrtext_s = i_label_short.
    ls_data_element-scrtext_m = i_label_medium.
    ls_data_element-scrtext_l = i_label_long.
*    ACTFLAG
*    APPLCLASS
*    AUTHCLASS
    ls_data_element-as4user = sy-uname.
    ls_data_element-as4date = sy-datum.
    ls_data_element-as4time = sy-uzeit.
    ls_data_element-dtelmaster = sy-langu.
*    RESERVEDTE
*    DTELGLOBAL
*    SHLPNAME
*    SHLPFIELD
*    DEFFDNAME
    ls_data_element-datatype = l_data_type.
    ls_data_element-leng = i_length.
    ls_data_element-decimals = i_decimals.
    ls_data_element-outputlen = i_length.
*    LOWERCASE
*    SIGNFLAG
*    CONVEXIT
*    VALEXI
*    ENTITYTAB
*    REFKIND
*    REFTYPE
*    PROXYTYPE
*    LTRFLDDIS
*    BIDICTRLC
*    NOHISTORY

    CALL FUNCTION 'DDIF_DTEL_PUT'
      EXPORTING
        name              = l_data_element   " Name of the Data Element to be Written
        dd04v_wa          = ls_data_element  " Sources of the Data Element
      EXCEPTIONS
        dtel_not_found    = 1                " No Sources for the Data Element
        name_inconsistent = 2                " Name in Sources Inconsistent with NAME
        dtel_inconsistent = 3                " Inconsistent Sources
        put_failure       = 4                " Write Error (ROLLBACK Recommended)
        put_refused       = 5                " Write not Allowed
        OTHERS            = 6.

    IF sy-subrc <> 0.
*   MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

      RETURN.

    ENDIF.

    CALL FUNCTION 'TR_TADIR_INTERFACE'
      EXPORTING
        wi_test_modus     = ' '
        wi_tadir_pgmid    = 'R3TR'
        wi_tadir_object   = 'DTEL'
        wi_tadir_obj_name = CONV sobj_name( l_data_element )
        wi_tadir_author   = sy-uname
        wi_tadir_devclass = l_package
        wi_set_genflag    = abap_true
      EXCEPTIONS
        OTHERS            = 0.

    COMMIT WORK.

  ENDMETHOD.

  METHOD read.

  ENDMETHOD.

  METHOD update.

  ENDMETHOD.

  METHOD delete.

  ENDMETHOD.

  METHOD get_translation.

  ENDMETHOD.

  METHOD set_translation.

  ENDMETHOD.

  METHOD activate.

    DATA l_rc TYPE i.

    CALL FUNCTION 'DDIF_DTEL_ACTIVATE'
      EXPORTING
        name        = i_data_element_name       " Name of the Data Element to be Activated
*       auth_chk    = 'X'                       " 'X': Perform Author. Check for DB Operations
*       prid        = -1                        " ID for Log Writer
      IMPORTING
        rc          = l_rc                      " Result of Activation
      EXCEPTIONS
        not_found   = 1                         " Data Element not Found
        put_failure = 2                         " Data Element could not be Written
        OTHERS      = 3.

    IF sy-subrc <> 0 OR l_rc <> 0.
*     MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

      r_activated = abap_false.

      RETURN.

    ENDIF.

    r_activated = abap_true.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_true.

    CASE abap_true.

      WHEN l_create.

        me->create(
          EXPORTING
            i_data_element_name = 'ZDE_TEST_DDIF_DTEL_PUT'
            i_short_description = 'Test DTEL create via DDIF_DTEL_PUT'
*            i_domain_name       =
            i_data_type         = 'CHAR'
            i_length            = 30
*            i_decimals          =
            i_label_short       = 'DTEL_PUT'
            i_label_medium      = 'DDIF_DTEL_PUT'
            i_label_long        = 'Test DTEL create via DDIF_DTEL_PUT'
            i_label_heading     = 'Test DTEL create via DDIF_DTEL_PUT'
            i_transport_request = ''
            i_package           = '$TMP'
          RECEIVING
            r_response          = l_response
        ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
