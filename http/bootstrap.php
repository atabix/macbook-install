<?php

use App\Request;
use App\Router;

$baseDir = __DIR__;

require __DIR__ .'/../vendor/autoload.php';
require __DIR__ .'/helpers.php';

$function = function () {
    $router = new Router(new Request());
    require app_path('/routes.php');
};

$function();
