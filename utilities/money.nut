/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * Money Management.
 */
class Money
{
	/**
	 * Try to get that amount of money
	 * @param money the amount of money to check. use '0' to get all.
	 * @return True if  I can get or have that amount of money / all possible loan although it is need to loan first
	 */
	function Get(money) {
		AIController.Sleep(1);
		local current_loan = AICompany.GetLoanAmount();
		local current_balance = Money.Balance();
		local loan_to_take = AICompany.GetMaxLoanAmount();

		/* take all possible loan or just amount of it*/
		if (money > 0) {
			if (Debug.Echo(current_balance > money, "Have", money)) return true;
			if (Debug.Echo(Money.Maximum() > money, "Can loan", money)) {
				/* now set the next loan to take */
				loan_to_take = (money - current_balance + current_loan).tointeger();
			} else {
				return false;
			}
		}
		/* all loan would be taken */
		if (current_balance > (loan_to_take * 4)) return true;
		Debug.ResultOf(AICompany.SetMinimumLoanAmount(AICompany.GetMaxLoanAmount()), "Set loan to max", AICompany.GetMaxLoanAmount());
		return true;
	}

	/**
	  * Pay all loan as much as possible
	  */
	function Pay() {
		AIController.Sleep(1);
		local cur_loan = AICompany.GetLoanAmount();
		local balance = Money.Balance();
		if (balance < 0) {
			AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
		}
		local interval = AICompany.GetLoanInterval();
		while (balance > interval) {
			if (cur_loan == 0) break;
			balance -= interval;
			cur_loan -= interval;
		}
		if (cur_loan != AICompany.GetLoanAmount()) {
			Debug.ResultOf(AICompany.SetLoanAmount(cur_loan), "Set loan to", cur_loan);
		}
	}

	/**
	 * Current AI Money Balance
	 * @return My bank balance at time calling
	 */
	function Balance() {
		return AICompany.GetBankBalance(AICompany.COMPANY_SELF);
	}

	/**
	 * @return maximal amount of funds that can be used.
	 */
	function Maximum() {
		return Money.Balance() + AICompany.GetMaxLoanAmount() - AICompany.GetLoanAmount();
	}
	/** Inflating **/
	function Inflated(x) {
		return (AICompany.GetMaxLoanAmount() / Setting.Get(Const.Settings.max_loan) * x).tointeger();
	}
};
