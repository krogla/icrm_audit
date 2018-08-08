// EW Ok
pragma solidity ^0.4.23;

// EW Ok
import './IcareumToken.sol';
// EW Ok
import './Adminable.sol';
// EW Ok
import './openzeppelin/Pausable.sol';
// EW Ok
import './openzeppelin/RefundVault.sol';
// EW Ok
import './openzeppelin/SafeMath.sol';

// EW Ok
contract IcareumCrowdsale is Adminable, Pausable {
    // EW Ok
    using SafeMath for uint256;
    // токен
    // EW Ok
    IcareumToken public token;
    // адрес на который будут поступать средства от продажи токенов после достижения softcap
    // EW Ok
    address public fundWallet;
    // хранилище, которое будет содержать средства инвесторов до достижения softcap
    // EW Ok
    RefundVault public vault;


    // токены пресейла
    // EW Ok
    uint256 public constant presaleTokenCap = 6000000;
    // EW Ok
    uint256 public presaleMintedTokens = 0;
    // максимальное количество токенов на каждом этапе основного сейла
    // EW Ok
    uint256 public constant mainsaleTokenCap1 = 15000000;
    // EW Ok
    uint256 public constant mainsaleTokenCap2 = 50000000;
    // EW Ok
    uint256 public constant mainsaleTokenCap3 = 56000000;
    // EW Ok
    uint256 public mainsaleMintedTokens = 0;
    // бонусы покупателям
    // EW Ok
    uint256 public constant mainsaleBonusTokenCap = 24000000;
    // EW Ok
    uint256 public mainsaleBonusMintedTokens = 0;
    // бонусные токены для баунти и маркетинга
    // EW Ok
    uint256 public constant marketingBonusTokenCap = 10000000;
    // EW Ok
    uint256 public marketingBonusMintedTokens = 0;
    // минимально необходимое эмитированное количество токенов основного сейла для вывода эфира с контракта
    // EW Ok
    uint256 public constant tokenSoftCap = 2500000; 


    // суммы единиц стоимости(1 единица = 0,1$) при покупке, за которые начисляются бонусные токены
    // EW Ok
    uint256 public constant mainsaleBonusLevel1 = 500000; // 50000$ - 10%
    // EW Ok
    uint256 public constant mainsaleBonusLevel2 = 1000000; // 100000$ - 15%
    // EW Ok
    uint256 public constant mainsaleBonusLevel3 = 2000000; // 200000$ - 20%


    // блок конца продажи основного сейла
    // EW Ok
    uint256 public endBlock;
    // курс эфира к доллару, определяется как количество веев за единицу стоимости(0,1$), т.к. стоимость токена всегда кратна этой сумме
    // EW Ok
    uint256 public rateWeiFor10Cent; 
    // количество полученных средств в веях
    // EW Ok
    uint256 public weiRaised = 0; 
    // факт старта продаж
    // EW Ok
    bool public crowdsaleStarted = false;
    // факт окончания продажи
    // EW Ok
    bool public crowdsaleFinished = false; 
    // автопауза продажи по достижению новой стадии
 //   bool public mainsaleAutopaused = false;
    // список приглашенных инвесторов
    // EW Ok
    mapping (address => bool) public isInvestor;
    // соответствие реферралов
    // EW Ok
    mapping (address => address) public referrerAddr;
    /**
    * событие покупки токенов
    * @param beneficiary тот, кто получил токены
    * @param value сумма в веях, заплаченная за токены
    * @param amount количество переданных токенов
    */
    // EW Ok
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    // начисление бонусов
    // EW Ok
    event BonusAdded(address referral, address referrer, uint256 amount);
    // событие начала краудсейла
    // EW Ok
    event Started();
    // событие окончания стадии краудсейла
    // EW Ok
    event MainsaleStageFinished(uint256 stage);
    // событие окончания краудсейла
    // EW Ok
    event Finished();
    // событие смены курса токена к доллару
    // EW Ok
    event RateChanged();
    /** Стадии
	 * - PreSale: Эмиссия токенов, проданных на пресейле
     * - MainSale: Основной краудсейл
     * - BonusDistribution: раздача бонусов после окончания основного сейла
     * - Successed: эмиссия окончена (устанавливается вручную)
     * - Failed: после окончания продажи софткап не достигнут
     */
    // EW Ok
    enum stateType {PreSale, MainSale, BonusDistribution, Successed, Failed}
    // EW Ok
    modifier onlyPresale {
        // EW Ok
     	require(crowdsaleState() == stateType.PreSale);
        // EW Ok
    	_;
  	}
    // EW Ok
    modifier onlyMainsale {
        // EW Ok
     	require(crowdsaleState() == stateType.MainSale);
        // EW Ok
    	_;
  	}
    // EW Ok
  	modifier onlyBonusDistribution {
        // EW Ok
     	require(crowdsaleState() == stateType.BonusDistribution);
        // EW Ok
    	_;  		
  	}
    // EW Ok
    modifier onlyMainsaleAndBonusDistribution {
        // EW Ok
        require(crowdsaleState() == stateType.MainSale || crowdsaleState() == stateType.BonusDistribution);
        // EW Ok
        _;
    }
    // EW Ok
  	modifier onlyFailed {
        // EW Ok
     	require(crowdsaleState() == stateType.Failed);
        // EW Ok
    	_;  		
  	} 
    // статус краудсейла
    // EW Ok
    function crowdsaleState() view public returns (stateType) {
        // EW Ok
    	if(!crowdsaleStarted) return stateType.PreSale;
        // EW Ok
    	else if(!_mainsaleHasEnded()) return stateType.MainSale;
        // EW Ok
    	else if(mainsaleMintedTokens < tokenSoftCap) return stateType.Failed;
        // EW Ok
    	else if(!crowdsaleFinished) return stateType.BonusDistribution;
        // EW Ok
    	else return stateType.Successed;
    }
    // стоимость токена в веях
    // EW Ok
    function rateOfTokenInWei() view public returns(uint256) {
        // EW Ok
       	return rateWeiFor10Cent.mul(_tokenPriceMultiplier()); 
    }  
    // проверка баланса токенов на адресе
    // EW Ok
    function tokenBalance(address _addr) view public returns (uint256) {
        // EW Ok
        return token.balanceOf(_addr);
    }
    // EW Ok
    // EW можно оптимизировать сделав массив isInvestor public, тогда для него автоматически создастся getter isInvestor(addr), а функцию убрать
    function checkIfInvestor(address _addr) view public returns (bool) {
        // EW Ok
        return isInvestor[_addr];
    }

    ///////////////////////////////////
    ///		   Инициализация   		///
    ///////////////////////////////////

    // конструктор контракта
    // @param _ethFundWallet: адрес, куда будет выводиться эфир 
    // @param _reserveWallet: адрес, куда зачислятся резервные токен
    // EW Ok
    constructor(address _ethFundWallet, address _reserveWallet) public {
        // EW Ok
        require(_ethFundWallet != 0x0);
        // EW Ok
        require(_reserveWallet != 0x0);
        // создание контракта токена с первоначальной эмиссией резервных токенов
        // EW Ok
        token = new IcareumToken();
        // кошель для сбора средств в эфирах
        // EW Ok
        fundWallet = _ethFundWallet;
        // хранилище, средства из которого могут быть перемещены на основной кошель только после достижения softcap
        // EW Ok
        vault = new RefundVault();
        // эмиссия резревных токенов
        // EW Ok
        _mintTokens(_reserveWallet,4000000);
    }
    // запуск продаж, изначально контракт находится в стадии эмиссии токенов этапа пресейла. После запуска эмиссия пресейла будет невозможна
    // EW Ok
    function startMainsale(uint256 _endBlock, uint256 _rateWeiFor10Cent) public
    onlyPresale 
    onlyOwner {
        // время конца продажи должно быть больше, чем время начала
        // EW Ok
        require(_endBlock > block.number);
        // курс эфира к доллару должен быть больше нуля
        // EW Ok
        require(_rateWeiFor10Cent > 0);
        // срок конца пресейла
        // EW Ok
        endBlock = _endBlock;
        // курс эфира к доллару
        // EW Ok
        rateWeiFor10Cent = _rateWeiFor10Cent;
        // старт
        // EW Ok
        crowdsaleStarted = true;
        // EW Ok
        emit Started(); 
    }

    ///////////////////////////////////
    ///		Администрирование		///
    ///////////////////////////////////
    // Инвесторы
    // админ добавляет вручную приглашенного инвестора
    // EW Ok
    function addInvestor(address _addr) public 
	onlyAdmin {
        // EW Ok
        isInvestor[_addr] = true;
    }
    // EW Ok
    function addReferral(address _addr, address _referrer) public 
    onlyAdmin {
        // EW Ok
        require(isInvestor[_referrer]);
        // EW Ok
        isInvestor[_addr] = true;
        // EW Ok
        referrerAddr[_addr] = _referrer;
    }
    // админ удаляет инвестора из списка
    // EW Ok
    function remInvestor(address _addr) public
    onlyAdmin {
        // EW Ok
        isInvestor[_addr] = false;
        // EW Ok
        referrerAddr[_addr] = 0x0;
    }

    // изменение фонодвого кошелька
    // EW Ok
    function changeFundWallet(address _fundWallet) public 
    onlyOwner {
        // EW Ok
        require(_fundWallet != 0x0);
        // EW Ok
        fundWallet = _fundWallet;
    }
    // изменение курса доллара к эфиру
    // EW Ok
    function changeRateWeiFor10Cent(uint256 _rate) public  
    onlyOwner {
        // EW Ok
        require(_rate > 0);
        // EW Ok
        rateWeiFor10Cent = _rate;
        // EW Ok
        emit RateChanged();
    }
    // эмиссия токенов, проданных на этапе пресейла. Допускает только эмиссию в рамках пресейл-капа
    // возможна только до начала основного сейла
    // EW Ok
    function mintPresaleTokens(address _beneficiary, uint256 _amount) public
    onlyPresale 
    onlyOwner {
        // EW Ok
        require(_beneficiary != 0x0);
        // EW Ok
        require(_amount > 0);
        // EW Ok
        presaleMintedTokens = presaleMintedTokens.add(_amount);
        // EW Ok
        require(presaleMintedTokens <= presaleTokenCap);
        // EW Ok
        _mintTokens(_beneficiary, _amount);
    }

    // эмиссия бонусных токенов. Возможна во время и после окончания основного сейла в рамках бонус-капа и до ручного завершения краудсейла владельцем
    // EW Ok
    function mintMarketingBonusTokens(address _beneficiary, uint256 _amount) public
    onlyMainsaleAndBonusDistribution 
    onlyOwner {
        // EW Ok
        require(_beneficiary != 0x0);
        // EW Ok
        require(_amount > 0);
        // EW Ok
        marketingBonusMintedTokens = marketingBonusMintedTokens.add(_amount);
        // EW Ok
        require(marketingBonusMintedTokens <= marketingBonusTokenCap);
        // EW Ok
        _mintTokens(_beneficiary, _amount);
    }

    // эмиссия бонусных токенов, оставшихся невыпущенными после завершения продажи. Возможна только после окончания основного сейла в рамках бонус-капа и до ручного завершения краудсейла владельцем
    // EW Ok
    function mintMainsaleBonusTokens(address _beneficiary, uint256 _amount) public
    onlyBonusDistribution 
    onlyOwner {
        // EW Ok
        require(_beneficiary != 0x0);
        // EW Ok
        require(_amount > 0);
        // EW Ok
        mainsaleBonusMintedTokens = mainsaleBonusMintedTokens.add(_amount);
        // EW Ok
        require(mainsaleBonusMintedTokens <= mainsaleBonusTokenCap);
        // EW Ok
        _mintTokens(_beneficiary, _amount);
    }
    // успешное окончание сейла и запрет дальнейшей эмиссии. Возможно только после окончания сейла
    // EW Ok
    function finalizeCrowdsale() public 
    onlyBonusDistribution 
    onlyOwner {
        // EW Ok
        token.finishMinting();
        // EW Ok
        crowdsaleFinished = true;
        // EW Ok
        emit Finished();
    }
    // владелец разрешает возвраты если softcap не достигнут
    // function allowRefunds() public
    // onlyFailed
    // onlyOwner {
    // 	vault.enableRefunds();
    // }
    // запрос владельем на выписку средств с хранилища если достигнут softcap
    // EW Ok
    function claimVaultFunds() public
    onlyOwner {
        // EW Ok
    	require(mainsaleMintedTokens >= tokenSoftCap);
        // EW Ok
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
    // EW Ok
    function () public payable {
        // EW Ok
        buyTokens();
    }
    // возвращает количество фактически полученных токенов
    // EW Ok
    function buyTokens() public payable returns (uint256) {
        // EW Ok
         _preValidatePurchase(msg.sender,msg.value);
        // EW Ok
        return _buyTokens(msg.sender,msg.value);

    }
    // запрос на возврат средств инвестором, возможно только если цель не достигнута и после установки владельцем стадии возврата
    // EW Ok
    function claimRefund() public
    onlyFailed {
        // EW Ok
        if (vault.state() == RefundVault.State.Active) {
            // EW Ok
            vault.enableRefunds();
        }
        // EW Ok
    	vault.refund(msg.sender);
    }

    ///////////////////////////////////
    ///   internal functions        ///
    ///////////////////////////////////  
     
    // функция покупки токенов инвестором
    // EW Ok
    function _buyTokens(address _buyer, uint256 _weiAmount) internal returns (uint256) {
        // EW Ok
        uint256 weiAmount = _weiAmount;
        // EW Ok
        uint256 tokenAmount = weiAmount.div(rateOfTokenInWei()); 
        //ограничение минимальной суммы покупки
        // EW Ok
        require(tokenAmount >= 100);

        //вовзрат сдачи если сумма в веях не кратна стоимости токенов
        // EW Ok
        uint256 change = weiAmount.sub(tokenAmount.mul(rateOfTokenInWei()));
        // EW Ok
        if (change > 0) {
            // EW Ok
            weiAmount = weiAmount.sub(change);
            // EW Ok
            _buyer.transfer(change);
        }

        //возврат сдачи если токенов по текущей цене меньше
        // EW Ok
        uint256 tokensLeft = _tokensLeftOnStage();
        // EW Ok
        if (tokenAmount > tokensLeft) {
            // EW Ok
            uint256 sumToReturn = tokenAmount.sub(tokensLeft).mul(rateOfTokenInWei());
            // EW Ok
            tokenAmount = tokensLeft;
            // EW Ok
            weiAmount = weiAmount.sub(sumToReturn);
            // EW Ok
            _buyer.transfer(sumToReturn);
        }
        // EW Ok
        if (tokenAmount == tokensLeft) {
            //достигнут предел токенов по текущей цене, ставим на паузу
            // EW Ok
            paused = true;
            // EW Ok
            emit MainsaleStageFinished(_tokenPriceMultiplier().sub(3));           
        }
     
        //бонусы
        // EW Ok
        uint256 mainsaleBonus = _mainsaleBonus(_buyer,tokenAmount);
        // EW Ok
        _referralBonus(_buyer,tokenAmount);

        // увеличить общее количество эмитированных токенов
        // EW Ok
        mainsaleMintedTokens = mainsaleMintedTokens.add(tokenAmount);
        // обновление счетчика присланных денег (капитализации)
        // EW Ok
        weiRaised = weiRaised.add(weiAmount);
        // эмиссия токенов
        // EW Ok
        _mintTokens(_buyer,tokenAmount);
        // EW Ok
        emit TokenPurchase(_buyer, weiAmount, tokenAmount);
        // списание средств
        // EW Ok
        _forwardFunds(_buyer,weiAmount);
        // EW Ok
        return tokenAmount.add(mainsaleBonus);
    }

    // расчет бонусов за сумму покупки. Должна быть вызвана до увеличения общей суммы эмиссии, иначе расчет может быть некорректным
    function _mainsaleBonus(address _buyer, uint256 _tokensBought) internal returns (uint256) {
        // EW Ok
        uint256 sumPayedInUSD = _tokensBought.mul(_tokenPriceMultiplier());
        // EW Ok
        if (sumPayedInUSD < mainsaleBonusLevel1) return 0;
        // EW Ok
        uint256 tokensToAdd = 0;
        // EW Ok
        if (sumPayedInUSD < mainsaleBonusLevel2) tokensToAdd = _tokensBought.div(10);               // 10%
        // EW Ok
        else if (sumPayedInUSD < mainsaleBonusLevel3) tokensToAdd = _tokensBought.mul(3).div(20);   // 15%
        // EW Ok
        else  tokensToAdd = _tokensBought.div(5);                                                   // 20%
        // EW Ok
        mainsaleBonusMintedTokens = mainsaleBonusMintedTokens.add(tokensToAdd);
        // EW Ok
        _mintTokens(_buyer,tokensToAdd);
        // EW Ok
        return tokensToAdd;
    }

    // расчет реферальных бонусов
    // EW Ok
    function _referralBonus(address _buyer, uint256 _tokensBought) internal {
        // EW Ok
        address referrer = referrerAddr[_buyer];
        // EW Ok
        if (referrer == 0x0) return;
        // EW Ok
        uint256 tokensToAdd = _tokensBought.div(20);
        // EW Ok
        mainsaleBonusMintedTokens = mainsaleBonusMintedTokens.add(tokensToAdd);
        // EW Ok
        _mintTokens(referrer,tokensToAdd);
        
    }

    // EW Ok
    function _tokensLeftOnStage() view internal returns(uint256) {
        // EW Ok
        if (mainsaleMintedTokens < mainsaleTokenCap1) return mainsaleTokenCap1.sub(mainsaleMintedTokens);
        // EW Ok
        else if (mainsaleMintedTokens < mainsaleTokenCap2) return mainsaleTokenCap2.sub(mainsaleMintedTokens);
        // EW Ok
        else if (mainsaleMintedTokens < mainsaleTokenCap3) return mainsaleTokenCap3.sub(mainsaleMintedTokens);
        // EW Ok
        else return 0;
    }
    // множитель стоимости токена относительно базы 0.1$
    // EW Ok
    function _tokenPriceMultiplier() view internal returns (uint256) {
        // EW Ok
        if (mainsaleMintedTokens < mainsaleTokenCap1) return 4;
        // EW Ok
        else if(mainsaleMintedTokens < mainsaleTokenCap2) return 5;
        // EW Ok
        else return 6;
    }

    // проверка возможности продажи токенов
    // EW Ok
    function _preValidatePurchase(address _beneficiary, uint256 _amount) view internal
    onlyMainsale 
    whenNotPaused {
        // при достижении новой стадии продажа останавливается до запуска вручную владельем
     //   require(!mainsaleAutopaused);
        // продолжить только если адрес пользователя есть в списке приглашенных инвесторов
        // EW Ok
        require(isInvestor[_beneficiary]);
        // инвестор не может прислать нулевое количество эфира
        // EW Ok
        require(_amount != 0);
    }

    // EW Ok
    function _mintTokens(address _beneficiary, uint256 _amount) internal {
        // EW Ok
        token.mint(_beneficiary,_amount.mul(1e18));   
    }
    // списание средств
    // EW Ok
    function _forwardFunds(address _beneficiary, uint256 _amount) internal {
    	// если количество собранных средств меньше softcap - отправляем в vault
        // EW Ok
    	if(mainsaleMintedTokens < tokenSoftCap) vault.deposit.value(_amount)(_beneficiary);
    	// если собрано больше - отправляем сразу на фондовый кошелек
        // EW Ok
        else fundWallet.transfer(_amount);    	
    }

    // проверка на окончание продажи токенов
    // EW Ok
    function _mainsaleHasEnded() view internal returns (bool) {
        // EW Ok
    	if(!crowdsaleStarted) return false;
        // EW Ok
        return  block.number > endBlock || mainsaleMintedTokens >= mainsaleTokenCap3;
    }

}