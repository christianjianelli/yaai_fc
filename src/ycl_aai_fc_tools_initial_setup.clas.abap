CLASS ycl_aai_fc_tools_initial_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_fc_tools_initial_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    MODIFY yaai_tool FROM TABLE @( VALUE #( ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new domain in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing domain.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for domains in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates an existing domain with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing domain.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing domain.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Sets translations for the fixed values of an existing domain in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Retrieves translations for the fixed values of an existing domain in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new data element in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing data element.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for data elements in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates an existing data element with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing data element.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing data element.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Sets translations for an existing data element in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Retrieves translations for an existing data element in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new structure in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing structure.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates an existing structure with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing structure.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for structures in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing structure.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new database table in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing database table.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates an existing database table with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing database table.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for database tables in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing database table.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new table type in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing table type.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates an existing table type with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing table type.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for table types in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing table type.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new message class with the specified description.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'ADD_MESSAGE'
                                              description = 'Adds a new message to an existing message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'UPDATE_MESSAGE'
                                              description = 'Updates an existing message in a message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'DELETE_MESSAGE'
                                              description = 'Deletes an existing message from a message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'READ_ALL_MESSAGES'
                                              description = 'Retrieves all messages from an existing message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Sets the translation for a message in a message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Retrieves the translation for a message in a message class.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates text elements for a program in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves text elements from a program in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates text elements for a program in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes a text element from a program.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'TRANSLATE'
                                              description = 'Translates text elements for a program into the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSPORT_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new transport request with the specified description and category.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSPORT_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing transport request.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSPORT_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for transport requests, optionally filtered by description.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'CREATE_REPORT_TRANSACTION'
                                              description = 'Creates a new report transaction with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'CREATE_DIALOG_TRANSACTION'
                                              description = 'Creates a new dialog transaction with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the details of an existing transaction.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for transactions in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing transaction.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Sets translations for an existing transaction in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSACTION_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Retrieves translations for an existing transaction in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_EMAIL_TOOLS'
                                              method_name = 'SEND_MAIL'
                                              description = 'Sends an email message.' )

                                            ( class_name = 'YCL_AAI_FC_RUNTIME_ERROR_TOOLS'
                                              method_name = 'GET_RUNTIME_ERRORS'
                                              description = 'Retrieves ABAP runtime errors from transaction ST22.' )

                                            ( class_name = 'YCL_AAI_FC_CI_TOOLS'
                                              method_name = 'RUN_INSPECTION'
                                              description = 'Executes a Code Inspector inspection for all objects included in the specified transport request and returns the inspection results.' )

                                            ( class_name = 'YCL_AAI_FC_CI_TOOLS'
                                              method_name = 'RUN_INSPECTION_VIA_JOB'
                                              description = 'Executes a Code Inspector inspection in a background job for all objects included in the specified transport request.' )

                                            ( class_name = 'YCL_AAI_FC_CI_TOOLS'
                                              method_name = 'GET_INSPECTION_RESULTS'
                                              description = 'Retrieves the results of a previously executed Code Inspector inspection for the specified transport request.' )

                                            ( class_name = 'YCL_AAI_FC_CI_TOOLS'
                                              method_name = 'GET_INSPECTION_STATUS'
                                              description = 'Retrieves the status of a Code Inspector inspection for the specified transport request.' )

                                            ( class_name = 'YCL_AAI_FC_ATC_TOOLS'
                                              method_name = 'RUN'
                                              description = 'Executes an ATC check for all objects included in the specified transport request and returns the results.' )

                                            ( class_name = 'YCL_AAI_FC_ATC_TOOLS'
                                              method_name = 'GET_RESULTS'
                                              description = 'Retrieves the results of a previously executed ATC check for the specified transport request.' )

                                            ( class_name = 'YCL_AAI_FC_SQL_TOOLS'
                                              method_name = 'EXECUTE_SQL_QUERY'
                                              description = 'Executes a SQL query on the SAP system and returns the results in JSON format.' )

                                            ( class_name = 'YCL_AAI_FC_SQL_TOOLS'
                                              method_name = 'EXECUTE_SQL_INSERT'
                                              description = 'Executes a SQL INSERT statement on the SAP system and returns the execution result.' )

                                            ( class_name = 'YCL_AAI_FC_SQL_TOOLS'
                                              method_name = 'EXECUTE_SQL_UPDATE'
                                              description = 'Executes a SQL UPDATE statement on the SAP system and returns the execution result.' )

                                            ( class_name = 'YCL_AAI_FC_SQL_TOOLS'
                                              method_name = 'EXECUTE_SQL_DELETE'
                                              description = 'Executes a SQL DELETE statement on the SAP system and returns the execution result.' )

                                            ( class_name = 'YCL_AAI_FC_CDS_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new CDS view in the SAP system.' )

                                            ( class_name = 'YCL_AAI_FC_CDS_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieves the source code of a CDS view.' )

                                            ( class_name = 'YCL_AAI_FC_CDS_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Searches for CDS views in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_CDS_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates an existing CDS view.' )

                                            ( class_name = 'YCL_AAI_FC_CDS_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Deletes an existing CDS view.' )

                                            ( class_name = 'YCL_AAI_FC_CDS_TOOLS'
                                              method_name = 'CHECK'
                                              description = 'Performs a validation check on an existing CDS view and returns any errors.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new ABAP class.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'READ'
                                              description = 'Returns the source code of an ABAP class.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Returns a list of ABAP classes matching the search criteria.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'GET_PROPERTIES'
                                              description = 'Returns the properties of an ABAP class.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates the source code of an existing ABAP class.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing ABAP class.' )

                                            ( class_name = 'YCL_AAI_FC_OO_CLASS_TOOLS'
                                              method_name = 'CHECK_SYNTAX'
                                              description = 'Perform a syntax check on the source code of an existing ABAP class.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Creates a new ABAP interface.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Returns the source code of an ABAP interface.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Returns a list of ABAP interface matching the search criteria.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'GET_PROPERTIES'
                                              description = 'Returns the properties of an ABAP interface.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Updates the source code of an existing ABAP interface.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activates an existing ABAP interface.' )

                                            ( class_name = 'YCL_AAI_FC_OO_INTERFACE_TOOLS'
                                              method_name = 'CHECK_SYNTAX'
                                              description = 'Perform a syntax check on the source code of an existing ABAP interface.' )

                                                ) ).

    out->write( |{ sy-dbcnt } tools inserted into table yaai_tool.| ).

  ENDMETHOD.

ENDCLASS.
