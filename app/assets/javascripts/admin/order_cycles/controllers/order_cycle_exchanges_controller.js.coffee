angular.module('admin.orderCycles')
  .controller 'AdminOrderCycleExchangesCtrl', ($scope, $controller, $filter, $window, $location, $timeout, OrderCycle, ExchangeProduct, Enterprise, EnterpriseFee, Schedules, RequestMonitor, ocInstance, StatusMessage) ->
    $controller('AdminEditOrderCycleCtrl', {$scope: $scope, ocInstance: ocInstance, $location: $location})

    $scope.supplier_enterprises = Enterprise.producer_enterprises
    $scope.distributor_enterprises = Enterprise.hub_enterprises

    $scope.exchangeSelectedVariants = (exchange) ->
      OrderCycle.exchangeSelectedVariants(exchange)

    $scope.exchangeDirection = (exchange) ->
      OrderCycle.exchangeDirection(exchange)

    $scope.enterprisesWithFees = ->
      $scope.enterprises[id] for id in OrderCycle.participatingEnterpriseIds() when $scope.enterpriseFeesForEnterprise(id).length > 0

    $scope.removeExchange = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.removeExchange(exchange)
      $scope.order_cycle_form.$dirty = true

    $scope.addExchangeFee = ($event, exchange) ->
      $event.preventDefault()
      OrderCycle.addExchangeFee(exchange)

    $scope.removeExchangeFee = ($event, exchange, index) ->
      $event.preventDefault()
      OrderCycle.removeExchangeFee(exchange, index)
      $scope.order_cycle_form.$dirty = true

    $scope.setPickupTimeFieldDirty = (index) ->
      $timeout ->
        pickup_time_field_name = "order_cycle_outgoing_exchange_" + index + "_pickup_time"
        $scope.order_cycle_form[pickup_time_field_name].$setDirty()

    $scope.removeDistributionOfVariant = (variant_id) ->
      OrderCycle.removeDistributionOfVariant(variant_id)

    $scope.loadExchangeProducts = (exchange, page = 1) ->
      enterprise = $scope.enterprises[exchange.enterprise_id]
      enterprise.supplied_products ?= []

      return if enterprise.last_page_loaded? && enterprise.last_page_loaded >= page
      enterprise.last_page_loaded = page

      incoming = true if $scope.view == 'incoming'
      params = { exchange_id: exchange.id, enterprise_id: exchange.enterprise_id, order_cycle_id: $scope.order_cycle.id, incoming: incoming, page: page}
      ExchangeProduct.index params, (products, num_of_pages, num_of_products) ->
        enterprise.num_of_pages = num_of_pages
        enterprise.num_of_products = num_of_products
        enterprise.supplied_products.push products...

    $scope.loadMoreExchangeProducts = (exchange) ->
      $scope.loadExchangeProducts(exchange, $scope.enterprises[exchange.enterprise_id].last_page_loaded + 1)

    $scope.loadAllExchangeProducts = (exchange) ->
      enterprise = $scope.enterprises[exchange.enterprise_id]
      return [] if enterprise.last_page_loaded >= enterprise.num_of_pages
      all_promises = []
      for page_to_load in [(enterprise.last_page_loaded + 1)..enterprise.num_of_pages]
        all_promises.push $scope.loadExchangeProducts(exchange, page_to_load).$promise
      all_promises

    # initialize exchange products panel if not yet done
    $scope.exchangeProdutsPanelInitialized = []
    $scope.initializeExchangeProductsPanel = (exchange) ->
      return if $scope.exchangeProdutsPanelInitialized[exchange.enterprise_id]
      $scope.loadExchangeProducts(exchange)
      $scope.exchangeProdutsPanelInitialized[exchange.enterprise_id] = true
