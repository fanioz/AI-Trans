/**
 * 		 09.02.05
 *      money.nut
 *      
 *      Copyright 2009 fanio zilla <fanio@arx-ads>
 *      
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *      
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */


/**
 * 
 * name: Class Bank
 * @note My money management on bank
 */
class Bank
{
	constructor() {}
  /**
  * 
  * name: Balance
  * @param none
  * @return My balance at time calling
  */
	static function Balance();
	
	/**
  * 
  * name: IHaveMoney
  * @param money the amount of money to check
  * @return True if  I have that amount of money although it is need loan first
  */
	static function IHaveMoney(money);
	
	/**
  * 
  * name: Get
  * @param money the amount of money to check (default = null - ALL)
  * @return True if  I can get that amount of money although it is need to loan first
  */
	static function Get(money);
	
	/**
  * 
  * name: PayLoan
  * @note Pay all loan as much as possible
  */
	static function PayLoan();
};

function Bank::Balance()
{
	return AICompany.GetBankBalance(AICompany.COMPANY_SELF);
}

function Bank::IHave(money)
{
	local theMoney = (Bank.Balance() + (AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount()) > money);	
	local theMsg	= (theMoney) ? "Yes, I Have " : "No, I Have'nt ";
	AILog.Info(theMsg + " amount " + money);
	return theMoney;
}

function Bank::Get(money = null)
{
	if (money == null || money == 0) {
		AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
		AILog.Info("Balance =" + Bank.Balance());
		return true;
	}
	/* future code */
	if (!Bank.IHave(money)) return false;
	if (Bank.Balance() > money) return true;
	local loan = money - Bank.Balance() + AICompany.GetLoanInterval() + AICompany.GetLoanAmount();
	loan = loan - loan % AICompany.GetLoanInterval();
	AICompany.SetLoanAmount(loan);
	ErrMessage("Increased loan to " + loan + " to get more " + money);
	return true;
}

function Bank::PayLoan()
{
  AIController.Sleep(5);
	local mymoney = Bank.Balance();		/// catch locally 
	local paying =  AICompany.GetLoanAmount() - (mymoney - mymoney % AICompany.GetLoanInterval());
	if (mymoney > AICompany.GetMaxLoanAmount()) paying = 0;
	AICompany.SetLoanAmount(paying);
	ErrMessage("Set Loan to " + paying);
}
