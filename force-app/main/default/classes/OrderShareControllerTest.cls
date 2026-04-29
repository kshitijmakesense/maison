@isTest
public class OrderShareControllerTest {

    // Utility method to create a test Order
    private static Order createTestOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order o = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert o;
        return o;
    }


    @isTest
    static void testConstructorAndMethods() {
        Order o = createTestOrder();
        
        // Create a StandardController
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(o);

        // Instantiate our controller
        OrderShareController controller = new OrderShareController(stdCtrl);

        System.assertNotEquals(null, controller.order, 'Order should be initialized');

        // Test downloadPDF()
        PageReference pdfRef = controller.downloadPDF();
        System.assertNotEquals(null, pdfRef);
        System.assertEquals(o.Id, pdfRef.getParameters().get('id'));

        // Test emailOrder()
        PageReference emailRef = controller.emailOrder();
        System.assert(emailRef.getUrl().contains(o.Id));

        // Test save()
        controller.order.Status = 'Activated';
        PageReference saveRef = controller.save();
        System.assertEquals(null, saveRef);

        // Test cancel()
        PageReference cancelRef = controller.cancel();
        System.assert(cancelRef.getUrl().contains(o.Id));
    }


    @isTest
    static void testGeneratePDFAndAttach() {
        Order o = createTestOrder();

        Test.startTest();
        OrderShareController.generatePDFAndAttach(o.Id);
        Test.stopTest();

        // Validate ContentVersion was inserted
        ContentVersion cv = [
            SELECT Id, FirstPublishLocationId, Title
            FROM ContentVersion
            WHERE FirstPublishLocationId = :o.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, cv, 'ContentVersion should be created');
        System.assertEquals(o.Id, cv.FirstPublishLocationId);
        System.assert(cv.Title.startsWith('Order_'), 'Title should include Order_ prefix');
    }
}