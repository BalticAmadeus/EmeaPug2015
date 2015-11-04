def temp-table ttInvoice like invoice.

/*------------------------------------------------------------------------------
Some code to initialize the environment or database before running the test.
------------------------------------------------------------------------------*/
PROCEDURE initialize:
END.


/*------------------------------------------------------------------------------
Some code run before every test to reset internal states, if needed.
------------------------------------------------------------------------------*/
PROCEDURE setUp:
END.


/*------------------------------------------------------------------------------
Some code run after a test to restore, log or something else.
------------------------------------------------------------------------------*/
PROCEDURE tearDown:
END.


/*------------------------------------------------------------------------------
Dispose everything, free resource, close files, disconnect databases, etc.
------------------------------------------------------------------------------*/
PROCEDURE dispose:
END.


procedure testCreateInvoice:
    def var invoice as class Invoice no-undo.

    invoice = new Invoice().

    create ttInvoice.
    assign
        ttInvoice.CustNum    = 1
        ttInvoice.InvoiceDat = today
        ttInvoice.Amount     = 1000
        ttInvoice.TotalPaid  = 1000
        ttInvoice.Adjustment = 0
        ttInvoice.OrderNum   = 1
        ttInvoice.ShipCharge = 0
    .

    invoice:init(table ttInvoice).
    invoice:saveInvoice().

    run assertTrue(invoice:getInvoiceNum() > 0).

    finally:
        delete object invoice no-error.
    end.
end.

procedure testDeleteInvoice:
    def var invoice as class Invoice no-undo.
    def var vId as int no-undo.

    invoice = new Invoice().

    find last invoice no-lock.
    vId = Invoice.Invoicenum.

    invoice:init(vId).
    invoice:deleteInvoice().

    find Invoice no-lock where
         Invoice.invoicenum = vId no-error.
    run assertFalse(avail invoice).

    finally:
        delete object invoice no-error.
    end.
end.
