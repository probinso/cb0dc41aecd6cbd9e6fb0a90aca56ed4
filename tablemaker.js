function getDates(input) {
    var dates = [];
    for (var i = 0; i < input.array.length; i++) {
        dates.push(input.array[i].date);
    }
    return dates;
}

function getByDate(input, date) {
    for (var i = 0; i < input.array.length; i++) {
        if (date == input.array[i].date) {
            return input.array[i].sites;
        }
    }
    return false;
}

function is_cond_in(input_array, cond) {
    for (var i = 0; i < input_array.length; i++) {
        if (cond(input_array[i])) {
            return true;
        }
    }
    return false;
}

function validsubstr_cond(sstring) {
    function retval(fstring) {
        if (fstring.indexOf(sstring) == -1) {
            return false;
        }
        return true;
    }
    return retval
}

function filter(sites, word) {
    var retval = [];
    for (var i = 0; i < sites.length; i++) {
        if (is_cond_in(sites[i].funnel, validsubstr_cond(word))) {
            retval.push(sites[i]);
        }
    }
    return retval;
}

/* helper functions to make sites_to_tables easier to read */
function cell(str) {
    return "<td>" + str + "</td>";
}

function row(str) {
    return "<tr>" + str + "</tr>";
}

function addcell(pre, elm) {
    return pre + cell(elm);
}

function addrow(pre, elm) {
    return pre + row(elm);
}

function sites_to_table(sites) {
    var acc = "<table> ";
    
    var rowtmp = "";
    for (var j = 0; j < sites[0].funnel.length; j++) {
        rowtmp = rowtmp.concat("<th>","Step : ", j.toString(), "</th>");
    }
    rowtmp = rowtmp.concat("<th>", "COUNT", "</th> ");
    acc = addrow(acc, rowtmp);
    
    
    for (var i = 0; i < sites.length; i++) {
        rowtmp = sites[i].funnel.map(cell).join("");
        rowtmp = addcell(rowtmp, sites[i].count.toString());
        acc = addrow(acc, rowtmp);
    }
    
    acc = acc.concat(" </table>")
    return acc;
}

