@isTest
public class ChatterHelperTest {

    @isTest
    static void testCleanBody_withHtml() {

        // Test data
        List<String> inputBodies = new List<String>{
            '<p>Hello test chatter</p>',
            '<div>Sample <b>Text</b></div>'
        };

        // Call method
        Test.startTest();
        List<String> result = ChatterHelper.cleanBody(inputBodies);
        Test.stopTest();

        // Assertions
        System.assertEquals(2, result.size());

        System.assertEquals('Hello test chatter', result[0]);
        System.assertEquals('Sample Text', result[1]);
    }

    @isTest
    static void testCleanBody_withNull() {

        List<String> inputBodies = new List<String>{
            null
        };

        Test.startTest();
        List<String> result = ChatterHelper.cleanBody(inputBodies);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('', result[0]);
    }

    @isTest
    static void testCleanBody_emptyList() {

        List<String> inputBodies = new List<String>();

        Test.startTest();
        List<String> result = ChatterHelper.cleanBody(inputBodies);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }
}