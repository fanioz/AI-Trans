/*  09.02.05 - money.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA 02110-1301, USA.
 */


/**
 * My money management on bank.
 */
class Bank
{
    /**
     * Try to get that amount of money
     * @param money the amount of money to check. use '0' to get all.
     * @return True if  I can get or have that amount of money / all possible loan although it is need to loan first
     */
    static function Get(money)
    {
        local current_loan = AICompany.GetLoanAmount();
        local current_balance = TransAI.Balance();
        local loan_to_take = AICompany.GetMaxLoanAmount();

        /* take all possible loan or just amount of it*/
        if (money > 0) {
            if (Debug.ResultOf("Have:" + money, current_balance > money)) return true;
            if (Debug.ResultOf("Out of range:" + money, (current_balance + loan_to_take - current_loan) < money)) return false;
            /* now set the real loan to take */
            loan_to_take = (money - current_balance + AICompany.GetLoanInterval() + current_loan).tointeger();
        } else {
            /* all loan was taken */
            if (current_loan == loan_to_take) return false;
            money = loan_to_take;
        }
        return AICompany.SetMinimumLoanAmount(Debug.ResultOf("Want to get " + money + " Increased loan to ", loan_to_take));
    }
}

/**
 * Current AI Bank Balance
 * @return My bank balance at time calling
 */
TransAI.Balance = function () {	return AICompany.GetBankBalance(AICompany.COMPANY_SELF); }

/**
  * Pay all loan as much as possible
  */
class Task.PayLoan extends DailyTask
{
	constructor()
	{
		::DailyTask.constructor("Paying Loan Task");
		::DailyTask.SetRemovable(false);
		::DailyTask.SetKey(30);
	}

	function Execute() {
		::DailyTask.Execute();
        AIController.Sleep(1);
		if (AICompany.SetLoanAmount(AICompany.GetLoanInterval())) return true;
        local current_loan = AICompany.GetLoanAmount();
        local paying = 0;
        /* nothing to paid */
        if (current_loan == 0) return false;
        /* nothing to pay with */
        if (TransAI.Balance() < AICompany.GetLoanInterval()) return false;
        if (TransAI.Balance() < AICompany.GetMaxLoanAmount()) {
            paying =  current_loan - (TransAI.Balance() - TransAI.Balance() % AICompany.GetLoanInterval());
        }
        return AICompany.SetLoanAmount(Debug.ResultOf("Set Loan to", paying));
	}
}
