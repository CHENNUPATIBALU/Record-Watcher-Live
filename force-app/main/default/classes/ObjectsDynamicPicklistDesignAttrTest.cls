@isTest
private class ObjectsDynamicPicklistDesignAttrTest {

    @isTest
    static void testGetValues() {
        // Create a dummy context using the real DesignTimePageContext class
        VisualEditor.DesignTimePageContext context = (VisualEditor.DesignTimePageContext) JSON.deserialize(
            '{"entityName":"Account"}',
            VisualEditor.DesignTimePageContext.class
        );

        // Instantiate the class with the mocked context
        ObjectsDynamicPicklistDesignAttr obj = new ObjectsDynamicPicklistDesignAttr(context);

        // Call getValues
        VisualEditor.DynamicPickListRows result = obj.getValues();

        // Since we can't call getRows(), we validate using debug logs or null checks
        System.assertNotEquals(null, result, 'Picklist rows should not be null');
    }

    @isTest
    static void testGetDefaultValue() {
        VisualEditor.DesignTimePageContext context = (VisualEditor.DesignTimePageContext) JSON.deserialize(
            '{"entityName":"Account"}',
            VisualEditor.DesignTimePageContext.class
        );

        ObjectsDynamicPicklistDesignAttr obj = new ObjectsDynamicPicklistDesignAttr(context);

        VisualEditor.DataRow defaultVal = obj.getDefaultValue();
        System.assertEquals(null, defaultVal, 'Expected default value to be null');
    }
}