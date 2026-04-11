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

    INSERT yaai_tool FROM TABLE @( VALUE #( ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new domain in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieve the details of an existing domain.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Search for domains in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Update an existing domain with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Delete an existing domain.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activate an existing domain.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Set the translation for an existing domain fixed values in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_DOMAIN_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Get the translation for an existing domain fixed values in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new data element in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieve the details of an existing data element.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Search for data elements in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Update an existing data element with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Delete an existing data element.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activate an existing data element.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Set the translation for an existing data element in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_DATA_ELEMENT_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Get the translation for an existing data element in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new structure in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieve the details of an existing structure.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Update an existing structure with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Delete an existing structure.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Search for structures in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_STRUCTURE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activate an existing structure.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new table in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieve the details of an existing table.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Update an existing table with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Delete an existing table.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Search for tables in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activate an existing table.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new table type in the ABAP Dictionary with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'READ'
                                              description = 'Retrieve the details of an existing table type.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Update an existing table type with the specified parameters.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Delete an existing table type.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Search for table types in the specified package, optionally filtered by name or description.' )

                                            ( class_name = 'YCL_AAI_FC_TABLE_TYPE_TOOLS'
                                              method_name = 'ACTIVATE'
                                              description = 'Activate an existing table type.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new message class with the specified description.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'ADD_MESSAGE'
                                              description = 'Add a new message to an existing message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'UPDATE_MESSAGE'
                                              description = 'Update an existing message in a message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'DELETE_MESSAGE'
                                              description = 'Delete an existing message from a message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'READ_ALL_MESSAGES'
                                              description = 'Read all messages from an existing message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'SET_TRANSLATION'
                                              description = 'Set the translation for a message in a message class.' )

                                            ( class_name = 'YCL_AAI_FC_MESSAGE_CLASS_TOOLS'
                                              method_name = 'GET_TRANSLATION'
                                              description = 'Get the translation for a message in a message class.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create text elements for a program in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'READ'
                                              description = 'Read text elements from a program in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'UPDATE'
                                              description = 'Update text elements for a program in the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'DELETE'
                                              description = 'Delete a specific text element from a program.' )

                                            ( class_name = 'YCL_AAI_FC_TEXT_POOL_TOOLS'
                                              method_name = 'TRANSLATE'
                                              description = 'Translate text elements for a program into the specified language.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSPORT_TOOLS'
                                              method_name = 'CREATE'
                                              description = 'Create a new transport request with the specified description and category.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSPORT_TOOLS'
                                              method_name = 'READ'
                                              description = 'Read the details of an existing transport request.' )

                                            ( class_name = 'YCL_AAI_FC_TRANSPORT_TOOLS'
                                              method_name = 'SEARCH'
                                              description = 'Search for transport requests, optionally filtered by description.' )

                                                ) ) ACCEPTING DUPLICATE KEYS.

    out->write( |{ sy-dbcnt } tools inserted into table yaai_tool.| ).

  ENDMETHOD.

ENDCLASS.
