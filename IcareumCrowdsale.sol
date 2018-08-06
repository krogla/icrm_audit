pragma solidity ^0.4.23;

import './IcareumToken.sol';
import './Adminable.sol';
import './openzeppelin/Pausable.sol';
import './openzeppelin/RefundVault.sol';
import './openzeppelin/SafeMath.sol';

contract IcareumCrowdsale is Adminable, Pausable {
    using SafeMath for uint256;
    // токен
    IcareumToken public token;
    // адрес на который будут поступать средства от продажи токенов после достижения softcap 
    address public fundWallet;
    // хранилище, которое будет содержать средства инвесторов до достижения softcap 
    RefundVault public vault;


    // токены пресейла
    uint256 public constant presaleTokenCap = 3000000; 
    uint256 public presaleMintedTokens = 0;
    // максимальное количество токенов на каждом этапе основного сейла
    uint256 public constant mainsaleTokenCap1 = 15000000; 
    uint256 public constant mainsaleTokenCap2 = 50000000; 
    uint256 public constant mainsaleTokenCap3 = 56000000; 
    uint256 public mainsaleMintedTokens = 0;
    // бонусы покупателям
    uint256 public constant mainsaleBonusTokenCap = 24000000;
    uint256 public mainsaleBonusMintedTokens = 0;
    // бонусные токены для баунти и маркетинга
    uint256 public constant marketingBonusTokenCap = 10000000; 
    uint256 public marketingBonusMintedTokens = 0;
    // минимально необходимое эмитированное количество токенов основного сейла для вывода эфира с контракта
    uint256 public constant tokenSoftCap = 2500000; 


    // суммы единиц стоимости(1 единица = 0,1$) при покупке, за которые начисляются бонусные токены
    uint256 public constant mainsaleBonusLevel1 = 500000; // 50000$ - 10%
    uint256 public constant mainsaleBonusLevel2 = 1000000; // 100000$ - 15%
    uint256 public constant mainsaleBonusLevel3 = 2000000; // 200000$ - 20%


    // блок конца продажи основного сейла
    uint256 public endBlock;
    // курс эфира к доллару, определяется как количество веев за единицу стоимости(0,1$), т.к. стоимость токена всегда кратна этой сумме
    uint256 public rateWeiFor10Cent; 
    // количество полученных средств в веях
    uint256 public weiRaised = 0; 
    // факт старта продаж
    bool public crowdsaleStarted = false;
    // факт окончания продажи
    bool public crowdsaleFinished = false; 
    // автопауза продажи по достижению новой стадии
 //   bool public mainsaleAutopaused = false;   
    // список приглашенных инвесторов
    mapping (address => bool) public isInvestor;  
    // соответствие реферралов
    mapping (address => address) public referrerAddr;
    /**
    * событие покупки токенов
    * @param beneficiary тот, кто получил токены
    * @param value сумма в веях, заплаченная за токены
    * @param amount количество переданных токенов
    */
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    // начисление бонусов
    event BonusAdded(address referral, address referrer, uint256 amount);
    // событие начала краудсейла
    event Started();
    // событие окончания стадии краудсейла
    event MainsaleStageFinished(uint256 stage);
    // событие окончания краудсейла
    event Finished();
    // событие смены курса токена к доллару
    event RateChanged();
    /** Стадии
	 * - PreSale: Эмиссия токенов, проданных на пресейле
     * - MainSale: Основной краудсейл
     * - BonusDistribution: раздача бонусов после окончания основного сейла
     * - Successed: эмиссия окончена (устанавливается вручную)
     * - Failed: после окончания продажи софткап не достигнут
     */
    enum stateType {PreSale, MainSale, BonusDistribution, Successed, Failed}
    modifier onlyPresale {
     	require(crowdsaleState() == stateType.PreSale);
    	_;
  	}
    modifier onlyMainsale {
     	require(crowdsaleState() == stateType.MainSale);
    	_;
  	}
  	modifier onlyBonusDistribution {
     	require(crowdsaleState() == stateType.BonusDistribution);
    	_;  		
  	}
    modifier onlyMainsaleAndBonusDistribution {
        require(crowdsaleState() == stateType.MainSale || crowdsaleState() == stateType.BonusDistribution);
        _;
    }
  	modifier onlyFailed {
     	require(crowdsaleState() == stateType.Failed);
    	_;  		
  	} 
    // статус краудсейла 
    function crowdsaleState() view public returns (stateType) {
    	if(!crowdsaleStarted) return stateType.PreSale;
    	else if(!_mainsaleHasEnded()) return stateType.MainSale;
    	else if(mainsaleMintedTokens < tokenSoftCap) return stateType.Failed;
    	else if(!crowdsaleFinished) return stateType.BonusDistribution;
    	else return stateType.Successed;
    }
    // стоимость токена в веях
    function rateOfTokenInWei() view public returns(uint256) {   
       	return rateWeiFor10Cent.mul(_tokenPriceMultiplier()); 
    }  
    // проверка баланса токенов на адресе
    function tokenBalance(address _addr) view public returns (uint256) {
        return token.balanceOf(_addr);
    }

    ///////////////////////////////////
    ///		   Инициализация   		///
    ///////////////////////////////////

    // конструктор контракта
    // @param _ethFundWallet: адрес, куда будет выводиться эфир 
    // @param _reserveWallet: адрес, куда зачислятся резервные токен
    constructor(address _ethFundWallet, address _reserveWallet) public {
        require(_ethFundWallet != 0x0);
        require(_reserveWallet != 0x0);
        // создание контракта токена с первоначальной эмиссией резервных токенов
        token = new IcareumToken();
        // кошель для сбора средств в эфирах
        fundWallet = _ethFundWallet;
        // хранилище, средства из которого могут быть перемещены на основной кошель только после достижения softcap 
        vault = new RefundVault();
        // эмиссия резревных токенов
        _mintTokens(_reserveWallet,7000000);
    }
    // запуск продаж, изначально контракт находится в стадии эмиссии токенов этапа пресейла. После запуска эмиссия пресейла будет невозможна
    function startMainsale(uint256 _endBlock, uint256 _rateWeiFor10Cent) public
    onlyPresale 
    onlyOwner {
        // время конца продажи должно быть больше, чем время начала
        require(_endBlock > block.number);
        // курс эфира к доллару должен быть больше нуля
        require(_rateWeiFor10Cent > 0);
        // срок конца пресейла
        endBlock = _endBlock;
        // курс эфира к доллару
        rateWeiFor10Cent = _rateWeiFor10Cent;
        // старт 
        crowdsaleStarted = true;
        emit Started(); 
    }

    ///////////////////////////////////
    ///		Администрирование		///
    ///////////////////////////////////
    // Инвесторы
    // админ добавляет вручную приглашенного инвестора
    function addInvestor(address _addr) public 
	onlyAdmin {      
        isInvestor[_addr] = true;
    }
    function addReferral(address _addr, address _referrer) public 
    onlyAdmin {
        require(isInvestor[_referrer]);
        isInvestor[_addr] = true;
        referrerAddr[_addr] = _referrer;
    }
    // админ удаляет инвестора из списка
    function remInvestor(address _addr) public
    onlyAdmin {
        isInvestor[_addr] = false;
        referrerAddr[_addr] = 0x0;
    }

    // изменение фонодвого кошелька
    function changeFundWallet(address _fundWallet) public 
    onlyOwner {
        require(_fundWallet != 0x0);
        fundWallet = _fundWallet;
    }
    // изменение курса доллара к эфиру
    function changeRateWeiFor10Cent(uint256 _rate) public  
    onlyOwner {
        require(_rate > 0);
        rateWeiFor10Cent = _rate;
        emit RateChanged();
    }
    // эмиссия токенов, проданных на этапе пресейла. Допускает только эмиссию в рамках пресейл-капа
    // возможна только до начала основного сейла
    function mintPresaleTokens(address _beneficiary, uint256 _amount) public
    onlyPresale 
    onlyOwner {
        require(_beneficiary != 0x0);
        require(_amount > 0);
        presaleMintedTokens = presaleMintedTokens.add(_amount);
        require(presaleMintedTokens <= presaleTokenCap);
        _mintTokens(_beneficiary, _amount);
    }

    // эмиссия бонусных токенов. Возможна во время и после окончания основного сейла в рамках бонус-капа и до ручного завершения краудсейла владельцем
    function mintMarketingBonusTokens(address _beneficiary, uint256 _amount) public
    onlyMainsaleAndBonusDistribution 
    onlyOwner {
        require(_beneficiary != 0x0);
        require(_amount > 0);
        marketingBonusMintedTokens = marketingBonusMintedTokens.add(_amount);
        require(marketingBonusMintedTokens <= marketingBonusTokenCap);
        _mintTokens(_beneficiary, _amount);
    }

    // эмиссия бонусных токенов, оставшихся невыпущенными после завершения продажи. Возможна только после окончания основного сейла в рамках бонус-капа и до ручного завершения краудсейла владельцем
    function mintMainsaleBonusTokens(address _beneficiary, uint256 _amount) public
    onlyBonusDistribution 
    onlyOwner {
        require(_beneficiary != 0x0);
        require(_amount > 0);
        mainsaleBonusMintedTokens = mainsaleBonusMintedTokens.add(_amount);
        require(mainsaleBonusMintedTokens <= mainsaleBonusTokenCap);
        _mintTokens(_beneficiary, _amount);
    }
    // успешное окончание сейла и запрет дальнейшей эмиссии. Возможно только после окончания сейла
    function finalizeCrowdsale() public 
    onlyBonusDistribution 
    onlyOwner {
        token.finishMinting();
        crowdsaleFinished = true;
        emit Finished();
    }
    // владелец разрешает возвраты если softcap не достигнут
    // function allowRefunds() public
    // onlyFailed 
    // onlyOwner {
    // 	vault.enableRefunds();
    // }
    // запрос владельем на выписку средств с хранилища если достигнут softcap
    function claimVaultFunds() public
    onlyOwner {
    	require(mainsaleMintedTokens >= tokenSoftCap);
    	vault.close(fundWallet);
    }
    // владелец снимает с автопаузы
    // function continueMainsale() public 
    // onlyOwner {
    //     mainsaleAutopaused = false;
    // }

    ///////////////////////////////////
    ///	  Операции для инвесторов   ///
    ///////////////////////////////////

    function () public payable {
        buyTokens();
    }
    // возвращает количество фактически полученных токенов
    function buyTokens() public payable returns (uint256) {

         _preValidatePurchase(msg.sender,msg.value);

        return _buyTokens(msg.sender,msg.value);

    }
    // запрос на возврат средств инвестором, возможно только если цель не достигнута  
    function claimRefund() public 
    onlyFailed {
        if (vault.state() == RefundVault.State.Active) {
            vault.enableRefunds();
        } 
    	vault.refund(msg.sender);
    }

    ///////////////////////////////////
    ///   internal functions        ///
    ///////////////////////////////////  
     
    // функция покупки токенов инвестором
    function _buyTokens(address _buyer, uint256 _weiAmount) internal returns (uint256) {
        uint256 weiAmount = _weiAmount;
        uint256 tokenAmount = weiAmount.div(rateOfTokenInWei()); 
        //ограничение минимальной суммы покупки
        require(tokenAmount >= 100);

        //вовзрат сдачи если сумма в веях не кратна стоимости токенов
        uint256 change = weiAmount.sub(tokenAmount.mul(rateOfTokenInWei()));
        if (change > 0) {
            weiAmount = weiAmount.sub(change);
            _buyer.transfer(change);
        }

        //возврат сдачи если токенов по текущей цене меньше
        uint256 tokensLeft = _tokensLeftOnStage(); 
        if (tokenAmount > tokensLeft) {
            uint256 sumToReturn = tokenAmount.sub(tokensLeft).mul(rateOfTokenInWei());
            tokenAmount = tokensLeft;
            weiAmount = weiAmount.sub(sumToReturn);
            _buyer.transfer(sumToReturn);
        }

        if (tokenAmount == tokensLeft) {                 
            //достигнут предел токенов по текущей цене, ставим на паузу
            paused = true;
            emit MainsaleStageFinished(_tokenPriceMultiplier().sub(3));           
        }
     
        //бонусы 
        uint256 mainsaleBonus = _mainsaleBonus(_buyer,tokenAmount);
        _referralBonus(_buyer,tokenAmount);

        // увеличить общее количество эмитированных токенов
        mainsaleMintedTokens = mainsaleMintedTokens.add(tokenAmount);
        // обновление счетчика присланных денег (капитализации)
        weiRaised = weiRaised.add(weiAmount);
        // эмиссия токенов
        _mintTokens(_buyer,tokenAmount);

        emit TokenPurchase(_buyer, weiAmount, tokenAmount);
        // списание средств 
        _forwardFunds(_buyer,weiAmount);

        return tokenAmount.add(mainsaleBonus);
    }

    // расчет бонусов за сумму покупки. Должна быть вызвана до увеличения общей суммы эмиссии, иначе расчет может быть некорректным
    function _mainsaleBonus(address _buyer, uint256 _tokensBought) internal returns (uint256) {
        uint256 sumPayedInUSD = _tokensBought.mul(_tokenPriceMultiplier());

        if (sumPayedInUSD < mainsaleBonusLevel1) return 0;

        uint256 tokensToAdd = 0;
        if (sumPayedInUSD < mainsaleBonusLevel2) tokensToAdd = _tokensBought.div(10);               // 10% 
        else if (sumPayedInUSD < mainsaleBonusLevel3) tokensToAdd = _tokensBought.mul(3).div(20);   // 15%
        else  tokensToAdd = _tokensBought.div(5);                                                   // 20%

        mainsaleBonusMintedTokens = mainsaleBonusMintedTokens.add(tokensToAdd);
        _mintTokens(_buyer,tokensToAdd);

        return tokensToAdd;
    }

    // расчет реферальных бонусов
    function _referralBonus(address _buyer, uint256 _tokensBought) internal {
        address referrer = referrerAddr[_buyer];

        if (referrer == 0x0) return;

        uint256 tokensToAdd = _tokensBought.div(20);
        
        mainsaleBonusMintedTokens = mainsaleBonusMintedTokens.add(tokensToAdd);
        _mintTokens(referrer,tokensToAdd);
        
    }

    function _tokensLeftOnStage() view internal returns(uint256) {
        if (mainsaleMintedTokens < mainsaleTokenCap1) return mainsaleTokenCap1.sub(mainsaleMintedTokens);
        else if (mainsaleMintedTokens < mainsaleTokenCap2) return mainsaleTokenCap2.sub(mainsaleMintedTokens);
        else if (mainsaleMintedTokens < mainsaleTokenCap3) return mainsaleTokenCap3.sub(mainsaleMintedTokens);
        else return 0;
    }
    // множитель стоимости токена относительно базы 0.1$
    function _tokenPriceMultiplier() view internal returns (uint256) {
        if (mainsaleMintedTokens < mainsaleTokenCap1) return 4;
        else if(mainsaleMintedTokens < mainsaleTokenCap2) return 5;
        else return 6;
    }

    // проверка возможности продажи токенов
    function _preValidatePurchase(address _beneficiary, uint256 _amount) view internal
    onlyMainsale 
    whenNotPaused {
        // при достижении новой стадии продажа останавливается до запуска вручную владельем
     //   require(!mainsaleAutopaused);
        // продолжить только если адрес пользователя есть в списке приглашенных инвесторов
        require(isInvestor[_beneficiary]);
        // инвестор не может прислать нулевое количество эфира
        require(_amount != 0);
    }

    function _mintTokens(address _beneficiary, uint256 _amount) internal {
        token.mint(_beneficiary,_amount.mul(1e18));   
    }
    // списание средств 
    function _forwardFunds(address _beneficiary, uint256 _amount) internal {
    	// если количество собранных средств меньше softcap - отправляем в vault 
    	if(mainsaleMintedTokens < tokenSoftCap) vault.deposit.value(_amount)(_beneficiary);
    	// если собрано больше - отправляем сразу на фондовый кошелек
        else fundWallet.transfer(_amount);    	
    }

    // проверка на окончание продажи токенов
    function _mainsaleHasEnded() view internal returns (bool) {
    	if(!crowdsaleStarted) return false;
        return  block.number > endBlock || mainsaleMintedTokens >= mainsaleTokenCap3;
    }

}