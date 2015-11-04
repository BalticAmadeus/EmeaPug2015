 /*------------------------------------------------------------------------
    File        : Invoice
    Purpose     : Creates, updates and deletes invoices.
    Notes       : Used for Invoice table (in Sports2000 db) manipulation.
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

class Invoice:
    def private temp-table ttInvoice like Invoice.

    def private var prId as int no-undo.

    constructor public Invoice ():
    end constructor.

    destructor public Invoice ():
    end destructor.
    
 /*------------------------------------------------------------------------------
    Purpose: Gets temp-table of invoice and checks if invoice is new or already in db.
    Notes: If new, returns char.
  ------------------------------------------------------------------------------*/
    method public char init (table ttInvoice):
        def var pInvoiceStatus as char no-undo initial "".
    end method.

 /*------------------------------------------------------------------------------
    Purpose: Gets invoice number and checks if invoice is in db or is deleted.
    Notes: If deleted, returns char.
  ------------------------------------------------------------------------------*/
    method public char init (pInvoiceNum as int):
        def var pInvoiceStatus as char no-undo initial "".

        empty temp-table ttInvoice.

        find Invoice no-lock where Invoice.Invoicenum = pInvoiceNum no-error.
        if avail Invoice
        then do:
            create ttInvoice.
            buffer-copy Invoice to ttInvoice.
        end.
        else pInvoiceStatus = "Invoice does not exist!".
        return pInvoiceStatus.
    end method.

 /*------------------------------------------------------------------------------
    Purpose: Updates existing invoice or saves new one.
    Notes: Validation method is used.
  ------------------------------------------------------------------------------*/
    method public char saveInvoice ():
        def var pSaveStatus as char no-undo initial "".
        def var pValidationStatus as char no-undo.

        find ttInvoice.

        find Invoice exclusive-lock where Invoice.Invoicenum = ttInvoice.Invoicenum no-error.
        if locked Invoice
        then pSaveStatus = "Invoice is locked by another user!".
        else do:
            if avail invoice
            then do:
                pValidationStatus = validateInvoice ().
                if pValidationStatus > ""
                then pSaveStatus = pValidationStatus.
                else do:
                    buffer-copy ttInvoice except ttInvoice.Invoicenum to Invoice.
                    pSaveStatus = "Changes were successfully saved.".
                end.
            end.
            else do:
                pValidationStatus = validateInvoice ().
                if pValidationStatus > ""
                then pSaveStatus = pValidationStatus.
                else do:
                    create Invoice.
                    buffer-copy ttInvoice to Invoice.
                    Invoice.Invoicenum = next-value(NextInvNum).
                    prId = Invoice.Invoicenum.
                end.
            end.
        end.
        return pSaveStatus.
    end method.

 /*------------------------------------------------------------------------------
    Purpose: Validates invoice data for further usage.
    Notes: Customer number and order number should already exist; invoice amount
    has to be more than 0; total paid amount and shipping charge should be more
    than zero.
  ------------------------------------------------------------------------------*/
    method public char validateInvoice ():
        def var pValidationStatus as char no-undo.
        
        find ttInvoice.
                
        /* Block checks if Customer exists */
        find Customer no-lock where Customer.CustNum = ttInvoice.CustNum no-error.
        if not available Customer
        then pValidationStatus = "The customer you entered does not exist!".

        /* Block checks if Order exists and if invoice date if later than order date */
        find Order no-lock where Order.OrderNum = ttInvoice.OrderNum no-error.
        if available Order
        then do:
            if ttInvoice.InvoiceDate <> ?
            then do:
                if Order.OrderDate > ttInvoice.InvoiceDate
                then pValidationStatus = substitute("&1 ~nInvoice date should be later than order date!", pValidationStatus).
            end.
            else pValidationStatus = substitute("&1 ~nEnter Invoice date!", pValidationStatus).
        end.
        else pValidationStatus = substitute("&1 ~nThe order you entered does not exist!", pValidationStatus).
      
        /* Block checks i Invoice Amount is more than zero */
        if ttInvoice.Amount <= 0
        then pValidationStatus = substitute("&1 ~nInvoice amount should be more than zero!", pValidationStatus).

        /* Block checks if Total paid amount is more than zero or equal to zero */
        if ttInvoice.TotalPaid < 0
        then pValidationStatus = substitute("&1 ~nTotal paid amount should be more than or equal to zero!", pValidationStatus).

        /* Block checks if Shipping charge is more than zero or equal to zero */
        if ttInvoice.Shipcharge < 0
        then pValidationStatus = substitute("&1 ~nShipping charge should be more than or equal to zero!", pValidationStatus).
        
        left-trim(pValidationStatus).
        return pValidationStatus.
    end method.
    
 /*------------------------------------------------------------------------------
    Purpose: Deletes existing invoice.
    Notes: Invoice has to be fully paid (invoice amount <= total paid amount +
    invoice adjustment.
  ------------------------------------------------------------------------------*/
    method public char deleteInvoice ():
        def var pDeleteStatus as char no-undo initial "".
        
        find ttInvoice.
        
        find Invoice exclusive-lock where 
             Invoice.Invoicenum = ttInvoice.Invoicenum no-error.
        if locked Invoice
        then pDeleteStatus = "Invoice is locked by another user!".
        else do:
            if available Invoice
            then do:
                if Invoice.Amount <= Invoice.TotalPaid + Invoice.Adjustment 
                then delete Invoice.
                else pDeleteStatus = "Only fully paid invoice can be deleted! Try again.".
            end.
            else pDeleteStatus = "Invoice was already deleted by another user!".
        end.
        return pDeleteStatus.
    end method.

    method public int getInvoiceNum():
        return prId.
    end method.

end class.
