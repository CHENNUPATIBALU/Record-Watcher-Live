global class ObjectsDynamicPicklistDesignAttr extends VisualEditor.DynamicPickList {
    
    VisualEditor.DesignTimePageContext context;
    
    global ObjectsDynamicPicklistDesignAttr(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }
    global override VisualEditor.DataRow getDefaultValue(){
        
        return null;
    }
    global override VisualEditor.DynamicPickListRows getValues() {
        String currentPageObjectName = context.entityName;
        VisualEditor.DynamicPickListRows  picklistValues = new VisualEditor.DynamicPickListRows();
        List<Schema.SObjectType> globalDescribeValues = Schema.getGlobalDescribe().values();
        for (Schema.SObjectType obj : globalDescribeValues) {
            System.debug(obj.getDescribe().getName()); // This line will print the API name
            VisualEditor.DataRow dataRow = new VisualEditor.DataRow(obj.getDescribe().getLabel(), obj.getDescribe().getName());
            picklistValues.addRow(dataRow);
        }
        
        return picklistValues;
    }
}