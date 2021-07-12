/**
 * @author            : Bruno Diaz
 * @lastModifiedDate  : 07-09-2021
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   07-09-2021   Bruno Diaz   Initial Version
**/
public class DBSchemaCreator {

    public static Map<Schema.DisplayType, String>  fieldTypeMap = new Map<Schema.DisplayType, String> {
        Schema.DisplayType.ANYTYPE => 'TEXT',
        Schema.DisplayType.BASE64 => 'TEXT',
        Schema.DisplayType.COMBOBOX => 'VARCHAR(255)',
        Schema.DisplayType.CURRENCY => 'DECIMAL',
        Schema.DisplayType.DATACATEGORYGROUPREFERENCE => 'CHAR',
        Schema.DisplayType.DATE => 'DATE',
        Schema.DisplayType.DATETIME => 'DATETIME',
        Schema.DisplayType.ENCRYPTEDSTRING => 'VARCHAR(255)',
        Schema.DisplayType.ID => 'CHAR',
        Schema.DisplayType.INTEGER => 'INTEGER',
        Schema.DisplayType.MULTIPICKLIST => 'VARCHAR(255)',
        Schema.DisplayType.PERCENT => 'DECIMAL',
        Schema.DisplayType.PHONE => 'VARCHAR(255)',
        Schema.DisplayType.PICKLIST => 'VARCHAR(255)',
        Schema.DisplayType.REFERENCE => 'CHAR',
        Schema.DisplayType.STRING => 'VARCHAR(255)',
        Schema.DisplayType.TIME => 'DATETIME',
        Schema.DisplayType.URL => 'VARCHAR(255)',
        Schema.DisplayType.DOUBLE => 'DECIMAL',
        Schema.DisplayType.LONG => 'DECIMAL',
        Schema.DisplayType.BOOLEAN => 'BOOLEAN',
        Schema.DisplayType.TEXTAREA => 'VARCHAR(255)',
        Schema.DisplayType.EMAIL => 'VARCHAR(255)'
    };

    public static final String CREATE_TABLE_STATEMENT = 'CREATE TABLE {0} ({1});';
    public static final String FIELD_STATEMENT = '{0} {1}';
    public static final String PRIMARY_KEY_STATEMENT = 'PRIMARY KEY ({0})';
    public static final String FOREIGN_KEY_STATEMENT = 'FOREIGN KEY ({0}) REFERENCES {1}({2})';
    public static final String[] objects = new String[]{
        'Account',
        'Contact',
        'User',
        'mtls__Address__c',
        'mtls__Pickup_Address__c',
        'mtls__Delivery_Option__c',
        'mtls__Delivery_Option_Data__c',
        'mtls__Quote__c',
        'mtls__Quote_Item__c',
        'mtls__Offline_Price_Request__c',
        'mtls__Quote_Approval_Request__c',
        'mtls__Part__c',
        'mtls__Part_Item__c',
        'mtls__Order__c',
        'mtls__Order_Item__c',
        'mtls__Payment_Transaction__c'
    };

    @AuraEnabled
    public static String getDescribe() {
        String[] statements = new String[]{};
        
        for(String objectName: objects) {
            statements.add(createTable(objectName ));
        }
        return String.join(statements,'');
    }

    @AuraEnabled
    public static String createTable(String objectName) {
        String[] fields = new String[]{};
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields
            .getMap();

        for(Schema.SObjectField field:fieldMap.values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            if(fieldDesc.isCustom() || fieldDesc.getName()== 'Id'|| fieldDesc.getName()== 'Name'|| fieldDesc.getName()== 'MasterLabel'|| fieldDesc.getName()== 'DeveloperName'){
                // Ensure all field types are contemplated
                if(!fieldTypeMap.containsKey(fieldDesc.getType())) { throw new UnexpectedException('FIELD TYPE IS NOT PRESENT IN MAPPING ' + fieldDesc.getType()); }
                String name= fieldDesc.getName().replace('mtls__','') ;
                String type = fieldTypeMap.get(fieldDesc.getType());

                if(!fieldDesc.isNillable()) type += ' NOT NULL';

                fields.add(name+' '+ type);
                
                if( fieldDesc.getType() == Schema.DisplayType.REFERENCE ) {
                    fields.add(
                        String.format(FOREIGN_KEY_STATEMENT, new String[]{
                            name,
                            fieldDesc.getReferenceTo()[0].getDescribe().getName().replace('mtls__',''),
                            'Id'
                        })
                    );
                } else if ( fieldDesc.getType() == Schema.DisplayType.ID ) {
                    fields.add(
                        String.format(PRIMARY_KEY_STATEMENT, new String[]{
                            name
                        })
                    );
                }
            }
        }

        String statement = String.format(
            CREATE_TABLE_STATEMENT, 
            new String[]{
                objectName.replace('mtls__',''),
                String.join(fields,',')
            }
        );

        System.debug(statement);
        return statement;
    }
}
